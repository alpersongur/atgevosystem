#!/usr/bin/env node

const {ESLint} = require("eslint");

(async () => {
  try {
    const eslint = new ESLint({fix: false});
    const results = await eslint.lintFiles(["."]);
    const formatter = await eslint.loadFormatter("stylish");
    const resultText = formatter.format(results);
    if (resultText) {
      console.log(resultText);
    }
    const errorCount = results.reduce((sum, item) => sum + item.errorCount, 0);
    if (errorCount > 0) {
      process.exitCode = 1;
    }
  } catch (error) {
    console.error(error);
    process.exitCode = 1;
  }
})();
