const express = require("express");
const request = require("request");
const app = express();
const path = require("path");

const PORT = 3122; // Set port

const Base64encode = function(unencoded) {
	return Buffer.from(unencoded || "").toString("base64");
};

const Base64decode = function(encoded) {
	return Buffer.from(encoded || "", "base64").toString("utf8");
};

const Base64urlEncode = function(unencoded) {
	var encoded = Base64encode(unencoded);
	return encoded.replace("+", "-").replace("/", "_").replace(/=+$/, "");
};

const Base64urlDecode = function(encoded) {
	encoded = encoded.replace("-", "+").replace("_", "/");
	while (encoded.length % 4)
		encoded += "=";
	return Base64decode(encoded);
};

app.get("/fivemauth", async (req, res) => {
	try {
		let AuthCode = req.query.code;
		let Base64Extra = req.query.state;
		let ExtraData = JSON.parse(Base64urlDecode(Base64Extra)); // Decodes the extradata from base64 into ASCII
		request.post({url: `http://localhost:${ExtraData.port}/OAuthFiveM/fivemauth?code=${AuthCode}&hash=${ExtraData.id}`});
		res.sendFile(path.resolve("./thanks.html"));
	} catch (e) {
		res.sendFile(path.resolve("./sorry.html"));
		console.log(`An error occured: ${e}\nIP: ${req.ip}`);
	}
});

let listener = app.listen(PORT, () => {
	console.log(`App now running at: ${listener.address().address}:${listener.address().port}`);
});