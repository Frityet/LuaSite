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

local path = require("pl.path")
local pretty = require("pl.pretty")
local file = require("pl.file")
local html_utilities = require("html")

local yield = coroutine.yield
local string = string
local pairs, ipairs = pairs, ipairs

---@class pages.todo
local export = {}

---@class ToDoItem
---@field title string
---@field description string
---@field done boolean

if not path.exists("todo.lua") then file.write("todo.lua", "{}") end

---@type ToDoItem[]
local items = assert(pretty.read(file.read("todo.lua")))

local function save_items() return assert(file.write("todo.lua", pretty.write(items))) end

function export.get()
    return html_utilities.generate_xml(function()
        ---@diagnostic disable: undefined-global
        return html {charset="utf8"} {
            head {
                title "LuaSite";
                default_style;

                script {src="https://github.com/fengari-lua/fengari-web/releases/download/v0.1.4/fengari-web.js", type="text/javascript"}
            };

            body {
                h1 "ToDo List";

                table {
                    tr {
                        th "Title";
                        th "Description";
                        th "Done";
                    };

                    function()
                        local all_completed = true

                        for _, item in ipairs(items) do
                            if all_completed then all_completed = item.done end
                            yield (
                                tr {
                                    td(item.title);
                                    td(item.description);
                                    td {
                                        --make sure the form is left to right, not going down
                                        form {style="display: inline-block", method="POST", action="/todo/"..item.title} {
                                            input {
                                                type = "submit";
                                                value = item.done and "Completed" or "Not Completed";
                                            };
                                        };
                                    };
                                }
                            )
                        end

                        if all_completed then
                            yield (
                                script {type="application/lua", async=true} [[
                                    local js = require("js")
                                    local window = js.global

                                    window:alert("All items completed!")
                                ]]
                            )
                        end
                    end
                };

                form {method="POST", action="/todo"} {
                    div {
                        label {["for"]="title"} "Title: ";

                        input {
                            type = "text";
                            name = "title";
                            id = "title";
                        };
                    };

                    div {
                        label {["for"] = "description"} "Description: ";

                        input {
                            type = "text";
                            name = "description";
                            id = "description";
                        };
                    };

                    div {
                        label {["for"]="done"} "Done: ";

                        input {
                            type = "checkbox";
                            name = "done";
                            id = "done";
                        };
                    };

                    div {
                        input {
                            type = "submit";
                            value = "Add";
                        };
                    };
                };
            };
        }
        ---@diagnostic enable: undefined-global
    end)
end

function export.post(request)
    local title = request.params.title
    if not title then
        return { redirect_to = "/todo" }
    end

    local description = request.params.description or ""
    local done = request.params.done or false

    if type(done) == "string" then
        done = done == "on"
    end

    items[#items+1] = {
        title = title;
        description = description;
        done = done;
    }
    save_items()

    return { redirect_to = "/todo" }
end

function export.update_entry(request)
    ---@type string?
    local item_name = request.params.item_name

    if item_name then
        --Replace the %20 with a space
        item_name = string.gsub(item_name, "%%20", " ")

        for _, item in ipairs(items) do
            if item.title == item_name then
                item.done = not item.done
                save_items()
                return { redirect_to = "/todo" }
            end
        end

        error("Item "..item_name.." not found!")
    end
end

return export
