from rest_framework import permissions
from rest_framework.request import Request
from rest_framework.views import APIView

class IsAdminUser(permissions.BasePermission):
    """
    允許管理員使用者存取。
    """
    def has_permission(self, request: Request, view: APIView) -> bool:
        return bool(request.user and request.user.is_staff)


class IsOwner(permissions.BasePermission):
    """
    僅允許對象的擁有者存取。
    """
    def has_object_permission(self, request: Request, view: APIView, obj) -> bool:
        # 檢查對象是否有 user_id 或 user 屬性
        if hasattr(obj, 'user_id'):
            return obj.user_id == request.user.id
        if hasattr(obj, 'user'):
            return obj.user == request.user
        return False


class ReadOnly(permissions.BasePermission):
    """
    僅允許唯讀請求。
    """
    def has_permission(self, request: Request, view: APIView) -> bool:
        return request.method in permissions.SAFE_METHODS


class IsTeacher(permissions.BasePermission):
    """
    允許具有教師角色的使用者存取。
    """
    def has_permission(self, request: Request, view: APIView) -> bool:
        return bool(request.user and hasattr(request.user, 'roles') and 'teacher' in request.user.roles)


class IsContentCreator(permissions.BasePermission):
    """
    允許具有內容創建者角色的使用者存取。
    """
    def has_permission(self, request: Request, view: APIView) -> bool:
        return bool(request.user and hasattr(request.user, 'roles') and 'content_creator' in request.user.roles)


class HasAccessToContentType(permissions.BasePermission):
    """
    根據使用者訂閱計劃，檢查是否有權限訪問特定內容類型。
    """
    def has_permission(self, request: Request, view: APIView) -> bool:
        # 獲取視圖中定義的內容類型
        content_type = getattr(view, 'content_type', None)
        if not content_type:
            return True
        
        # 檢查使用者是否有權限訪問該內容類型
        user = request.user
        if user.is_superuser or user.is_staff:
            return True
            
        if not hasattr(user, 'subscription'):
            return False
            
        return content_type in user.subscription.allowed_content_types