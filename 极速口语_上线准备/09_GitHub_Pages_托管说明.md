# GitHub Pages 托管说明

静态页在仓库根目录 docs/：privacy.html（ASC 必填）、terms.html、support.html。

## 启用步骤

1. 推送仓库到 GitHub（botonwa83-byte/jisukouyu）。
2. Settings → Pages → Source: Deploy from a branch → main / docs → Save。
3. 预期链接：
   - https://botonwa83-byte.github.io/jisukouyu/privacy.html
   - https://botonwa83-byte.github.io/jisukouyu/terms.html
   - https://botonwa83-byte.github.io/jisukouyu/support.html
4. curl 校验 200 后，把 privacy 填入 ASC 隐私政策 URL，support 填入支持网址。

## 注意

- App 内未硬编码这三个 URL，无需求改代码。
- 免费账户 Pages 需仓库 Public。
