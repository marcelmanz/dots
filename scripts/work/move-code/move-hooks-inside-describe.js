const fs = require('fs');
const path = require('path');
const glob = require('fast-glob');
const recast = require('recast');

const parser = {
  parse: source => {
    const tsParser = require('@typescript-eslint/parser');
    return tsParser.parse(source, {
      sourceType: 'module',
      ecmaVersion: 2020,
      loc: true,
      range: true,
      tokens: true,
      comment: true,
      ecmaFeatures: { jsx: true },
    });
  },
};

const HOOK_NAMES = new Set(['beforeEach', 'afterEach', 'beforeAll', 'afterAll']);

function moveHooksIntoFirstDescribe(filePath) {
  const source = fs.readFileSync(filePath, 'utf8');
  const ast = recast.parse(source, { parser });

  const topLevelHooks = [];
  let firstDescribeBody = null;

  recast.types.visit(ast, {
    visitExpressionStatement(path) {
      const expr = path.node.expression;
      if (expr?.type === 'CallExpression' && HOOK_NAMES.has(expr.callee.name)) {
        topLevelHooks.push(path.node);
        path.prune();
        return false;
      }
      this.traverse(path);
    },

    visitCallExpression(path) {
      const { callee, arguments: args } = path.node;
      if (
        callee.type === 'Identifier' &&
        callee.name === 'describe' &&
        args.length === 2 &&
        args[1].type === 'ArrowFunctionExpression' &&
        args[1].body.type === 'BlockStatement'
      ) {
        firstDescribeBody = args[1].body;
        return false;
      }
      this.traverse(path);
    },
  });

  if (topLevelHooks.length > 0 && firstDescribeBody) {
    firstDescribeBody.body.unshift(...topLevelHooks);
    fs.writeFileSync(filePath, recast.print(ast).code, 'utf8');
    console.log(`✅ Updated ${filePath}`);
  } else if (topLevelHooks.length > 0) {
    console.warn(`⚠️ Found hooks but no suitable describe() in ${filePath}`);
  }
}

async function run() {
  const inputPath = process.argv[2];

  if (!inputPath) {
    console.error('❌ Please provide a file or directory path as an argument.');
    process.exit(1);
  }

  const fullPath = path.resolve(inputPath);
  const isDir = fs.existsSync(fullPath) && fs.lstatSync(fullPath).isDirectory();

  const patterns = isDir
    ? [path.join(fullPath, '**/*.test.ts'), path.join(fullPath, '**/*.test.tsx')]
    : [fullPath];

  const files = await glob(patterns, {
    ignore: ['node_modules'],
    absolute: true,
  });

  if (files.length === 0) {
    console.warn('⚠️ No test files found to process.');
    return;
  }

  for (const file of files) {
    moveHooksIntoFirstDescribe(file);
  }
}

run().catch(err => {
  console.error('💥 Script failed:', err);
  process.exit(1);
});
