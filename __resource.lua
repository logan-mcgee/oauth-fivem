-- Manifest
resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"

server_scripts {
	"@mysql-async/lib/MySQL.lua",
	"server.js",
	"sha256.lua",
	"defferal-handler.lua",
	"exports.lua"
} 

server_exports {
	"UrlEncode",
	"UrlDecode",
	"Discord",
	"GetUserRoles"
}