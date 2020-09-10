const { setHttpCallback } = require("@citizenfx/http-wrapper");
const request = require("request");
const Koa = require("koa");
const Router = require("koa-router");
const app = new Koa();
const router = new Router();
const querystring = require("querystring");
const config = require("./config.json");

// main code

router.post("/fivemauth", (ctx, next) => {
	let params = querystring.decode(ctx.querystring);
	if (params.code && params.hash) {
		let UserCode = params.code;
		let UserHash = params.hash;
		request({
			url: `https://discordapp.com/api/oauth2/token`, 
			form: {
				client_id: config.public_data.client_id,
				client_secret: config.private_data.client_secret,
				grant_type: "authorization_code",
				code: UserCode,
				redirect_uri: config.public_data.redirect_uri
			},
			method: "POST",
			headers: {
				"Content-Type": "application/x-www-form-urlencoded"
			}
		}, 
		(err, res, body) => {
			let data = JSON.parse(body);

			request({url: "https://discordapp.com/api/users/@me", method: "GET", headers: {"Authorization": `Bearer ${data.access_token}`}}, 
			(err, res, body) => {
				// eslint-disable-next-line no-undef
				emit("OAuthFiveM:AuthedUser", body, UserHash); //* Send the info to Lua where we deal with adding them to the database and more.
			});
		});
	}
});

app.use(router.routes()).use(router.allowedMethods());
setHttpCallback(app.callback());

// BASE64 Encoding

const Base64encode = function(unencoded) {
	return new Buffer.from(unencoded || "").toString("base64");
};

const Base64decode = function(encoded) {
	return new Buffer.from(encoded || "", "base64").toString("utf8");
};

const Base64urlEncode = function(unencoded) {
	var encoded = Base64encode(unencoded);
	return encoded.replace("+", "-").replace("/", "_").replace(/=+$/, "");
};

exports("UrlEncode", Base64urlEncode);

const Base64urlDecode = function(encoded) {
	encoded = encoded.replace("-", "+").replace("_", "/");
	while (encoded.length % 4)
		encoded += "=";
	return Base64decode(encoded);
};

exports("UrlDecode", Base64urlDecode);