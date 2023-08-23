---@diagnostic disable: lowercase-global
package = "luasite"
version = "dev-1"
source = {
    url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
    homepage = "*** please enter a project homepage ***",
    license = "GPLv3"
}
dependencies = {
    "lua ~> 5.1",
    "lapis",
    "tabular",
    "penlight",
    "compat53"
}
build = {
    type = "builtin",
    modules = {
        app = "app.lua",
        config = "config.lua",
        models = "models.lua",
        html = "html.lua"
    }
}
