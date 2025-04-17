// move-vi-mocks.js
const fs = require("fs");
const path = require("path");
const glob = require("fast-glob");
const recast = require("recast");

const parser = {
  parse: (source) => {
    const tsParser = require("@typescript-eslint/parser");
    return tsParser.parse(source, {
      sourceType: "module",
      ecmaVersion: 2020,
      loc: true,
      range: true,
      tokens: true,
      comment: true,
      ecmaFeatures: { jsx: true },
    });
  },
};

// Helper to reconèixer vi.mock(...) o vi.mocks(...)
function isViMockCall(expr) {
  return (
    expr?.type === "CallExpression" &&
    expr.callee?.type === "MemberExpression" &&
    expr.callee.object.type === "Identifier" &&
    expr.callee.object.name === "vi" &&
    // vi.mock(...)
    ((expr.callee.property.type === "Identifier" &&
      (expr.callee.property.name === "mock" ||
        expr.callee.property.name === "mocks")) ||
      // vi['mock'](...)
      (expr.callee.property.type === "Literal" &&
        (expr.callee.property.value === "mock" ||
          expr.callee.property.value === "mocks")))
  );
}

function moveMocksIntoFirstDescribe(filePath) {
  const source = fs.readFileSync(filePath, "utf8");
  const ast = recast.parse(source, { parser });

  const topLevelMocks = [];
  let firstDescribeBody = null;

  recast.types.visit(ast, {
    // Capture and retalla els vi.mock(s) top‑level
    visitExpressionStatement(path) {
      const expr = path.node.expression;
      if (isViMockCall(expr)) {
        topLevelMocks.push(path.node);
        path.prune(); // elimina del nivell global
        return false; // no cal seguir baixant
      }
      this.traverse(path);
    },

    // Troba el primer describe(...)
    visitCallExpression(path) {
      const { callee, arguments: args } = path.node;
      if (
        callee.type === "Identifier" &&
        callee.name === "describe" &&
        args.length === 2 &&
        args[1].type === "ArrowFunctionExpression" &&
        args[1].body.type === "BlockStatement"
      ) {
        firstDescribeBody = args[1].body;
        return false; // ja hem trobat el primer describe
      }
      this.traverse(path);
    },
  });

  // Inserta els mocks trobats
  if (topLevelMocks.length > 0 && firstDescribeBody) {
    firstDescribeBody.body.unshift(...topLevelMocks);
    fs.writeFileSync(filePath, recast.print(ast).code, "utf8");
    console.log(`✅ Updated ${filePath}`);
  } else if (topLevelMocks.length > 0) {
    console.warn(
      `⚠️ Found vi.mock(s) but no suitable describe() in ${filePath}`,
    );
  }
}

async function run() {
  const inputPath = process.argv[2];

  if (!inputPath) {
    console.error("❌ Please provide a file or directory path as an argument.");
    process.exit(1);
  }

  const fullPath = path.resolve(inputPath);
  const isDir = fs.existsSync(fullPath) && fs.lstatSync(fullPath).isDirectory();

  const patterns = isDir
    ? [path.join(fullPath, "**/*.test.{ts,tsx,js,jsx}")]
    : [fullPath];

  const files = await glob(patterns, {
    ignore: ["node_modules"],
    absolute: true,
  });

  if (files.length === 0) {
    console.warn("⚠️ No test files found to process.");
    return;
  }

  for (const file of files) {
    moveMocksIntoFirstDescribe(file);
  }
}

run().catch((err) => {
  console.error("💥 Script failed:", err);
  process.exit(1);
});
