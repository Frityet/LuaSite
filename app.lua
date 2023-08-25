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

local default_style = html_utilities.style {
    h1 = {
        ["font-family"] = "sans-serif"
    };

    table = {
        ["font-family"] = { "arial", "sans-serif" };
        ["border-collapse"] = "collapse";
        ["width"] = "100%";
    };

    [{ "td", "th" }] = {
        ["border"] = "1px solid #dddddd";
        ["text-align"] = "left";
        ["padding"] = "8px";
    };

    ["tr:nth-child(even)"] = {
        ["background-color"] = "#dddddd";
    };

    div = {
        ["border-radius"] = "5px";
        ["background-color"] = "#f2f2f2";
        ["padding"] = "20px";
    };
}

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

                p { style = "font-family: sans-serif" } "This is a test of LuaSite. It is a Lua web framework that uses Lapis";

                h2 "Debug";

                h1 "Here is a table";
                div {disabled=true} {
                    html_utilities.table(request);
                }
            },
        }
        ---@diagnostic enable: undefined-global
    end)
end)

return app
