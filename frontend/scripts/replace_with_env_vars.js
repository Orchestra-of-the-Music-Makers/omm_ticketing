const path = require("path");
const fs = require("fs");

const srcFiles = ["public/index.html"];

srcFiles.forEach((srcFile, i) => {
  const srcContent = fs.readFileSync(srcFile, { encoding: "utf8" });
  const newContent = srcContent.replace("{API_KEY}", process.env.API_KEY);
  const newerContent = newContent.replace(
    "{LAMBDA_URL}",
    process.env.LAMBDA_URL
  );
  fs.writeFile(srcFile, newerContent, "utf8", function (err) {
    if (err) return console.log(err);
  });
});
