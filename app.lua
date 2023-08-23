local lapis = require("lapis")
local pretty = require("pl.pretty")
local tabular = require("tabular")
local app = lapis.Application()

local html_utilities = require("html")

local type = type

local pairs, ipairs = pairs, ipairs
local yield = coroutine.yield

local print = print

local tostring = tostring

---Turns a lua table into an html table, recursively, with multiple levels of nesting
---@param tbl table
---@return HTML.Node
local function html_table(tbl)
    ---@diagnostic disable: undefined-global
    return table {
        function()
            for k, v in pairs(tbl) do
                local val do
                    if type(v) == "table" then
                        if (getmetatable(v) or {}).__tostring then
                            val = tostring(v)
                        else
                            val = html_table(v)
                        end
                    else val = tostring(v) end
                end

                yield (
                    tr {
                        td(tostring(k));
                        td(val);
                    }
                )
            end
        end
    }
    ---@diagnostic enable: undefined-global
end
html_utilities.declare_xml_generator(html_table)

local default_style = html_utilities.generate_xml_node(function()
    ---@diagnostic disable: undefined-global
    return style [[
        h1 {
            font-family: sans-serif;
        }

        table {
            font-family: arial, sans-serif;
            border-collapse: collapse;
            width: 100%;
        }

        td, th {
            border: 1px solid #dddddd;
            text-align: left;
            padding: 8px;
        }

        tr:nth-child(even) {
            background-color: #dddddd;
        }

        div {
            border-radius: 5px;
            background-color: #f2f2f2;
            padding: 20px;
        }
    ]];
    ---@diagnostic enable: undefined-global
end)

app:get("/calculator", function(request)
    return html_utilities.generate_xml(function()
        ---@diagnostic disable: undefined-global
        return html {
            head {
                title "Calculator";
                default_style;
            };

            body {
                h1 "Calculator";

                form { method = "post", action = "/calculator" } {
                    ul {
                        li {
                            label { ["for"] = "first" } "First Number";
                            input { type = "number", name = "first", id = "first" };
                        };
                    };

                    ul {
                        li {
                            label { ["for"] = "operator" } "Operator";
                            ---@diagnostic disable-next-line: param-type-mismatch
                            select { name = "operator", id = "operator" } {
                                option { value = "Add" } "Add";
                                option { value = "Subtract" } "Subtract";
                                option { value = "Multiply" } "Multiply";
                                option { value = "Divide" } "Divide";
                            };
                        };
                    };

                    ul {
                        li {
                            label { ["for"] = "second" } "Second Number";
                            input { type = "number", name = "second", id = "second" };
                        };
                    };

                    ul {
                        li {
                            input { type = "submit", value = "Calculate" };
                        };
                    };
                };
            };
        }
        ---@diagnostic enable: undefined-global
    end)
end)

app:post("/calculator", function(request)
    local first = tonumber(request.params.first)
    local second = tonumber(request.params.second)
    local operator = request.params.operator

    ---@type number
    local result do
        if operator == "Add" then
            result = first + second
        elseif operator == "Subtract" then
            result = first - second
        elseif operator == "Multiply" then
            result = first * second
        elseif operator == "Divide" then
            result = first / second
        end
    end

    return html_utilities.generate_xml(function()
        ---@diagnostic disable: undefined-global
        return html {
            head {
                title "Calculator";
                default_style;
            };

            body {
                h1 "Calculator";

                div {
                    h1 "Result";
                    p (result);

                    h2 "Debug";
                    html_table(request);
                };
            };
        }
        ---@diagnostic enable: undefined-global
    end)
end)

app:get("/", function(request)
    return html_utilities.generate_xml(function()
        ---@diagnostic disable: undefined-global
        return html {charset="utf8"} {
            head {
                title "LuaSite";
                default_style;
            };

            body {
                h1 "LuaSite";

                p "This is a test of LuaSite. It is a Lua web framework that uses Lapis";

                h2 "Debug";

                h1 "Here is a table";
                html_table(request);
            },
        }
        ---@diagnostic enable: undefined-global
    end)
end)

return app
