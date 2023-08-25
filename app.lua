local lapis = require("lapis")
local todo = require("pages.todo")
local app = lapis.Application()

local html_utilities = require("html")

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

    a = {
        ["text-decoration"] = "none";
    };

    ["a:hover"] = {
        ["opacity"] = "0.7";
    };

    ["input[type=submit]"] = {
        ["background-color"] = "#4CAF50";
        ["border"] = "none";
        ["color"] = "white";
        ["padding"] = "15px 32px";
        ["text-align"] = "center";
        ["text-decoration"] = "none";
        ["display"] = "inline-block";
        ["font-size"] = "16px";
        ["margin"] = "4px 2px";
        ["cursor"] = "pointer";
    };

    ["input[type=checkbox]"] = {
        ["width"] = "20px";
        ["height"] = "20px";
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
                li {
                    a {href="/todo"} "ToDo List";
                };

                h2 "Debug";
                html_utilities.table(request);
            },
        }
        ---@diagnostic enable: undefined-global
    end)
end)

app:get("/todo", todo.get)
app:post("/todo", todo.post)
app:post("/todo/:item_name", todo.update_entry)

return app
