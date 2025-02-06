在Markdown-it中实现代码块的自动换行并保留缩进，可以通过以下两种方式实现。

$f(x)$

$$g(x)$$

$$f(x)g(x)\sum_{k=1}^na_kx^kf(x)g(x)\sum_{k=1}^na_kx^kf(x)g(x)\sum_{k=1}^na_kx^kf(x)g(x)\sum_{k=1}^na_kx^kf(x)g(x)\sum_{k=1}^na_kx^kf(x)g(x)\sum_{k=1}^na_kx^kf(x)g(x)\sum_{k=1}^na_kx^kf(x)g(x)\sum_{k=1}^na_kx^k$$



### 方案一：纯CSS实现（推荐）
```css
/* 保留缩进且自动换行 */
pre code {
  white-space: pre-wrap !important;  /* 保留空白但允许换行 */
  word-wrap: break-word !important;  /* 长单词换行 */
  
  /* 可选：添加水平滚动条作为备用方案 */
  overflow-x: auto;
  
  /* 增强缩进显示 */
  display: block;
  padding-left: 1em;  /* 缩进补偿 */
  text-indent: -1em;  /* 负缩进对齐 */
}
```

### 方案二：通过Markdown-it渲染器修改
```javascript
const md = require('markdown-it')();

// 覆写代码块渲染逻辑
md.renderer.rules.fence = (tokens, idx, options, env, self) => {
  const token = tokens[idx];
  return `<pre class="code-block" style="white-space: pre-wrap; word-wrap: break-word;">
    <code>${md.utils.escapeHtml(token.content)}</code>
  </pre>`;
};

// 同时处理缩进式代码块
md.renderer.rules.code_block = (tokens, idx, options, env, self) => {
  const token = tokens[idx];
  return `<pre class="code-block" style="white-space: pre-wrap; word-wrap: break-word;">
    <code>${md.utils.escapeHtml(token.content)}</code>
  </pre>`;
};
```

### 组合方案最佳实践（推荐）
```javascript
// 1. 配置Markdown-it添加容器class
const md = require('markdown-it')({
  html: true,
  highlight: function (str, lang) {
    return `<pre class="code-container"><code class="language-${lang}">${md.utils.escapeHtml(str)}</code></pre>`;
  }
});

// 2. CSS样式增强
/*
.code-container {
  white-space: pre-wrap;
  word-wrap: break-word;
  counter-reset: line;
  padding-left: 2em;  /* 统一缩进 */
}

.code-container code {
  display: block;
  position: relative;
  text-indent: -2em;
  padding-left: 2em;
}
*/
```

### 注意事项
1. **缩进处理**：通过`padding-left`和负`text-indent`的组合，可以完美保留原始缩进
2. **响应式支持**：添加`overflow-x: auto`作为移动端备用方案
3. **语法高亮兼容**：此方案能与highlight.js/Prism.js等常用高亮库协同工作
4. **行号显示**：如需显示行号，建议使用伪元素实现：
```css
.code-container code::before {
  counter-increment: line;
  content: counter(line);
  position: absolute;
  left: -2em;
  width: 2em;
  text-align: right;
  color: #999;
}
```

选择方案一时仅需添加CSS样式，方案二适用于需要动态处理内容的情况。推荐组合使用Class标记和CSS样式的方式，既有更好的维护性也保持扩展性。
