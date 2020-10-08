const path = require("path");
const fs = require("fs");

const srcFiles = ["public/index.html"];

srcFiles.forEach((srcFile, i) => {
  const srcContent = fs.readFileSync(srcFile, { encoding: "utf8" });
  const withApiKey = srcContent.replace(
    "{API_KEY}",
    process.env.API_KEY
  );
  const withLambdaUrl = withApiKey.replace(
    "{LAMBDA_URL}",
    process.env.LAMBDA_URL
  );
  const withTncLink = withLambdaUrl.replace(
    "{TNC_LINK}",
    process.env.TNC_LINK
  );
  const withPostConcertSurvey = withTncLink.replace(
    "{POST_CONCERT_SURVEY}",
    process.env.POST_CONCERT_SURVEY
  );
  const withConcertBooklet = withPostConcertSurvey.replace(
    "{CONCERT_BOOKLET_LINK}",
    process.env.CONCERT_BOOKLET_LINK
  );
  fs.writeFile(srcFile, withConcertBooklet, "utf8", function (err) {
    if (err) return console.log(err);
  });
});
