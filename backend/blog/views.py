import json
from django.http import JsonResponse, HttpResponseNotAllowed, HttpResponseNotFound
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Q
from .models import Article


@csrf_exempt
def articles(request):
    if request.method == "GET":
        published = request.GET.get("published")
        q = request.GET.get("q")
        page = int(request.GET.get("page", "1") or "1")
        page_size = int(request.GET.get("page_size", "10") or "10")
        if page < 1:
            page = 1
        if page_size < 1:
            page_size = 10
        qs = Article.objects.all()
        if published is not None:
            qs = qs.filter(published=published.lower() == "true")
        if q:
            qs = qs.filter(Q(title__icontains=q) | Q(content__icontains=q))
        total = qs.count()
        start = (page - 1) * page_size
        end = start + page_size
        rows = qs.order_by("-created_at")[start:end]
        items = [
            {
                "id": a.id,
                "title": a.title,
                "slug": a.slug,
                "content": a.content,
                "published": a.published,
                "created_at": a.created_at.isoformat(),
                "updated_at": a.updated_at.isoformat(),
            }
            for a in rows
        ]
        resp = {
            "results": items,
            "pagination": {
                "page": page,
                "page_size": page_size,
                "total": total,
                "total_pages": (total + page_size - 1) // page_size,
            },
        }
        return JsonResponse(resp)
    if request.method == "POST":
        try:
            payload = json.loads(request.body.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            payload = {}
        title = payload.get("title") or ""
        content = payload.get("content") or ""
        published = bool(payload.get("published", False))
        article = Article.objects.create(title=title, content=content, published=published)
        data = {
            "id": article.id,
            "title": article.title,
            "slug": article.slug,
            "content": article.content,
            "published": article.published,
            "created_at": article.created_at.isoformat(),
            "updated_at": article.updated_at.isoformat(),
        }
        return JsonResponse(data, status=201)
    return HttpResponseNotAllowed(["GET", "POST"])


@csrf_exempt
def article(request, pk):
    try:
        obj = Article.objects.get(pk=pk)
    except Article.DoesNotExist:
        return HttpResponseNotFound()
    if request.method == "GET":
        data = {
            "id": obj.id,
            "title": obj.title,
            "slug": obj.slug,
            "content": obj.content,
            "published": obj.published,
            "created_at": obj.created_at.isoformat(),
            "updated_at": obj.updated_at.isoformat(),
        }
        return JsonResponse(data)
    if request.method in ("PUT", "PATCH"):
        try:
            payload = json.loads(request.body.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            payload = {}
        for field in ["title", "content", "published"]:
            if field in payload:
                setattr(obj, field, payload[field])
        obj.save()
        data = {
            "id": obj.id,
            "title": obj.title,
            "slug": obj.slug,
            "content": obj.content,
            "published": obj.published,
            "created_at": obj.created_at.isoformat(),
            "updated_at": obj.updated_at.isoformat(),
        }
        return JsonResponse(data)
    if request.method == "DELETE":
        obj.delete()
        return JsonResponse({"deleted": True})
    return HttpResponseNotAllowed(["GET", "PUT", "PATCH", "DELETE"])
