-- Copyright (C) 2023 Amrit Bhogal
--
-- This file is part of LuaSite.
--
-- LuaSite is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- LuaSite is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with LuaSite.  If not, see <http://www.gnu.org/licenses/>.

---@class html_utilities
local export = {}

---@class HTML.Node
---@field tag string
---@field children (HTML.Node | string | fun(): HTML.Node)[]
---@field attributes { [string] : string }

---@param str string
---@return string
function export.sanitize_string(str)
    return (str:gsub("[<>&\"']", {
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["&"] = "&amp;",
        ["\""] = "&quot;",
        ["'"] = "&#39;"
    }))
end

---@param x any
---@return type | string
local function typename(x)
    local mt = getmetatable(x)
    if mt and mt.__type then
        return mt.__type
    else
        return type(x)
    end
end

---@param node HTML.Node
---@return string
function export.node_to_string(node)
    local html = "<"..node.tag

    for k, v in pairs(node.attributes) do
        html = html.." "..k.."=\""..export.sanitize_string(v).."\""
    end

    html = html..">"

    for i, v in ipairs(node.children) do
        if type(v) ~= "table" then
            html = html..export.sanitize_string(tostring(v))
        else
            html = html..export.node_to_string(v)
        end
    end

    html = html.."</"..node.tag..">"

    return html
end

---@generic T
---@param fn T
---@return T
function export.declare_xml_generator(fn)
    setfenv(fn, setmetatable({}, {
        ---@param self table
        ---@param tag_name string
        __index = function (self, tag_name)
            ---@param attributes { [string] : string, [integer] : (HTML.Node | string | fun(): HTML.Node) } | string
            ---@return table | fun(children: (HTML.Node | string | fun(): HTML.Node)[]): HTML.Node
            return function (attributes)
                ---@type HTML.Node
                local node = {
                    tag = tag_name,
                    children = {},
                    attributes = {}
                }

                --if we have a situation such as
                --[[
                    tag "string"
                ]]--
                --then the content is the `string`
                local tname = typename(attributes)
                if tname ~= "table" and tname ~= "HTML.Node" then
                    node.attributes = attributes and { tostring(attributes) } or {}
                elseif tname == "HTML.Node" then
                    ---local tag = div { p "hi" }
                    ---div(tag)
                    node.children = { attributes }
                    attributes = {}
                else
                    node.attributes = attributes --[[@as any]]
                end

                for i, v in ipairs(node.attributes) do
                    if type(v) == "function" then
                        export.declare_xml_generator(v)
                        v = coroutine.wrap(v)
                        for sub in v do
                            node.children[#node.children+1] = sub
                        end
                    else
                        node.children[#node.children+1] = v
                    end

                    node.attributes[i] = nil
                end

                return setmetatable(node, {
                    __type = "HTML.Node",

                    __tostring = export.node_to_string,

                    ---@param self HTML.Node
                    ---@param children (HTML.Node | string | fun(): HTML.Node)[]
                    __call = function (self, children)
                        if type(children) ~= "table" then
                            children = { tostring(children) }
                        end

                        for _, v in ipairs(children) do
                            if type(v) == "function" then
                                export.declare_xml_generator(v)
                                v = coroutine.wrap(v)
                                for sub in v do
                                    self.children[#self.children+1] = sub
                                end
                            else
                                self.children[#self.children+1] = v
                            end
                        end

                        return self
                    end
                })
            end
        end
    }))

    return fn
end

---Usage:
--[=[
```lua
local generate_html = require("html")

local str = generate_html(function()
    return html {
        head {
            title "Hello"
        },
        body {
            div { id = "main" } {
                h1 "Hello",
                img { src = "http://leafo.net/hi" }
                p [[This is a paragraph]]
            }
        }
    }
end)

```
]=]
---@param ctx fun(): table
---@return string
function export.generate_xml(ctx)
    return export.node_to_string(export.declare_xml_generator(ctx)())
end

---@param ctx fun(): table
---@return HTML.Node
function export.generate_xml_node(ctx)
    return export.declare_xml_generator(ctx)()
end

---Turns a lua table into an html table, recursively, with multiple levels of nesting
---@param tbl table
---@return HTML.Node
function export.table(tbl)
    ---@diagnostic disable: undefined-global
    return table {
        function()
            local function getval(v)
                if type(v) == "table" then
                    if (getmetatable(v) or {}).__tostring then
                        return tostring(v)
                    else
                        return html_table(v)
                    end
                else
                    return tostring(v)
                end
            end

            for i, v in ipairs(tbl) do
                yield (
                    tr {
                        td(tostring(i));
                        td(getval(v));
                    }
                )

                tbl[i] = nil
            end

            for k, v in pairs(tbl) do
                yield (
                    tr {
                        td(tostring(k));
                        td(getval(v));
                    }
                )
            end
        end
    }
    ---@diagnostic enable: undefined-global
end
export.declare_xml_generator(export.table)

---@param css { [string] : { [string | string[]] : (string | string[]) } }
---@return HTML.Node
function export.style(css)
    local css_str = ""
    for selector, properties in pairs(css) do
        css_str = css_str..selector.." {\n"
        for property, value in pairs(properties) do
            if type(value) == "table" then
                value = table.concat(value, ", ")
            end

            if type(value) == "table" then
                value = table.concat(value, ", ")
            end
            css_str = css_str.."    "..property..": "..value..";\n"
        end
        css_str = css_str.."}\n"
    end

    return export.generate_xml_node(function ()
        ---@diagnostic disable: undefined-global
        return style(css_str)
        ---@diagnostic enable: undefined-global
    end)
end

return export
