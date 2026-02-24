# Godot + Django 博客示例

一个使用 Django 提供文章 REST API、使用 Godot 4 作为客户端的示例项目。支持文章的增删改查、搜索、分页、详情弹窗、以及导出为 JSON/Markdown。

## 技术栈
- 后端：Django 3.2 + SQLite，REST API 路由在 `/api/articles/`
- 前端：Godot 4（Vulkan），通过 `HTTPRequest` 访问后端
- 跨域：自定义中间件允许跨域访问

## 快速开始（后端）
在项目根目录执行：

```powershell
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
.venv\Scripts\python backend\manage.py migrate
.venv\Scripts\python backend\manage.py runserver 0.0.0.0:8000
```

验证接口：
- 打开浏览器访问 http://127.0.0.1:8000/api/articles/
- 返回 JSON 表示后端启动成功

## 运行 Godot 前端
1. 打开 Godot 4 稳定版（推荐 4.2+）
2. 选择项目目录 `godot_client` 并打开
3. 点击运行，主场景 `Main.tscn` 会展示 UI
4. 使用说明：
   - 刷新：加载文章列表
   - 搜索：输入关键字，列表自动筛选
   - 分页：上一页/下一页，支持 5/10/20/50 每页条数选择
   - 新建/保存/删除：在表单区进行编辑和管理
   - 详情弹窗：双击列表项弹出详情
   - 导出：支持导出为 JSON/Markdown，导出前会自动拉取最新详情并弹出保存文件对话框

## API 约定
- 列表与创建：`GET/POST /api/articles/`
  - 查询参数：
    - `page`（默认 1）、`page_size`（默认 10）
    - `q`（搜索标题或内容）
    - `published=true/false`（可选）
  - 返回示例：
    ```json
    {
      "results": [{ "id": 1, "title": "示例", "content": "...", "published": true, "slug": "shi-li", "created_at": "...", "updated_at": "..." }],
      "pagination": { "page": 1, "page_size": 10, "total": 1, "total_pages": 1 }
    }
    ```
- 单条操作：`GET/PUT/PATCH/DELETE /api/articles/<id>/`

## 代码位置
- 后端入口与设置：
  - [manage.py](file:///c:/Users/TD/code/godot/godot_django_blog/backend/manage.py)
  - [settings.py](file:///c:/Users/TD/code/godot/godot_django_blog/backend/backend/settings.py)
  - [urls.py](file:///c:/Users/TD/code/godot/godot_django_blog/backend/backend/urls.py)
  - [middleware.py](file:///c:/Users/TD/code/godot/godot_django_blog/backend/backend/middleware.py)
- 文章模块：
  - [models.py](file:///c:/Users/TD/code/godot/godot_django_blog/backend/blog/models.py)
  - [views.py](file:///c:/Users/TD/code/godot/godot_django_blog/backend/blog/views.py)
  - [migrations/0001_initial.py](file:///c:/Users/TD/code/godot/godot_django_blog/backend/blog/migrations/0001_initial.py)
- Godot 客户端：
  - [project.godot](file:///c:/Users/TD/code/godot/godot_django_blog/godot_client/project.godot)
  - [Main.tscn](file:///c:/Users/TD/code/godot/godot_django_blog/godot_client/Main.tscn)
  - [Main.gd](file:///c:/Users/TD/code/godot/godot_django_blog/godot_client/Main.gd)

## 开发工具
- 代码检查（Ruff）：
  ```powershell
  .venv\Scripts\python -m ruff check backend
  ```
- 示例脚本（验证接口并创建示例数据）：
  ```powershell
  .venv\Scripts\python backend\scripts\check_api.py
  ```

## 注意事项
- `.gitignore` 已包含虚拟环境、Godot 编辑器缓存、测试缓存、环境变量文件、SQLite 数据库等（避免提交体积和敏感信息）
  - [.gitignore](file:///c:/Users/TD/code/godot/godot_django_blog/.gitignore)
- 生产环境请替换 `settings.py` 中的 `SECRET_KEY` 并关闭 `DEBUG`

