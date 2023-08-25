local lapis = require("lapis")
local pretty = require("pl.pretty")
local file = require("pl.file")
local path = require("pl.path")
local tabular = require("tabular")
local app = lapis.Application()

local html_utilities = require("html")

local type = type

local pairs, ipairs = pairs, ipairs
local yield = coroutine.yield

local string = string
local print = print
local tostring = tostring

---@class ToDoItem
---@field title string
---@field description string
---@field done boolean

if not path.exists("todo.lua") then file.write("todo.lua", "{}") end

---@type ToDoItem[]
local items = assert(pretty.read(file.read("todo.lua")))

local function save_items() return assert(file.write("todo.lua", pretty.write(items))) end

print("Todo items:\n", tabular.show(items, { "title", "description", "done" }))

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

app:get("/todo", function()
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
                                        form {style = "display: inline-block", method="POST", action="/todo/"..item.title} {
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
                                script { type="application/lua", async=true } [[
                                    local js = require("js")
                                    local window = js.global

                                    window:alert("All items completed!")
                                ]]
                            )
                        end
                    end
                };

                form {
                    method = "POST";
                    action = "/todo";

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
end)

app:post("/todo/:item_name", function(self)
    ---@type string?
    local item_name = self.params.item_name

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

    local title = self.params.title
    if not title then
        return { redirect_to = "/todo" }
    end

    local description = self.params.description or ""
    local done = self.params.done or false

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
end)

return app
