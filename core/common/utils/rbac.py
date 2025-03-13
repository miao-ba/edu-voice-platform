from typing import List, Dict, Any, Optional
from django.contrib.auth.models import User
from django.db.models import Q

class RBACService:
    """角色基礎存取控制服務"""
    
    @classmethod
    def get_user_permissions(cls, user_id: int) -> List[str]:
        """
        獲取使用者的所有權限列表
        
        Args:
            user_id: 使用者 ID
            
        Returns:
            權限列表
        """
        from django.contrib.auth.models import Permission
        from django.contrib.auth import get_user_model
        
        User = get_user_model()
        
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return []
            
        # 獲取使用者直接權限
        direct_permissions = user.user_permissions.all()
        
        # 獲取使用者通過群組的權限
        group_permissions = Permission.objects.filter(group__user=user)
        
        # 合併權限並去重
        permissions = set()
        for perm in direct_permissions:
            permissions.add(f"{perm.content_type.app_label}.{perm.codename}")
        
        for perm in group_permissions:
            permissions.add(f"{perm.content_type.app_label}.{perm.codename}")
            
        return list(permissions)
    
    @classmethod
    def check_permission(cls, user_id: int, permission: str) -> bool:
        """
        檢查使用者是否有指定權限
        
        Args:
            user_id: 使用者 ID
            permission: 權限字符串 (例如：'app_label.codename')
            
        Returns:
            是否具有權限
        """
        from django.contrib.auth import get_user_model
        
        User = get_user_model()
        
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return False
            
        # 超級使用者具有所有權限
        if user.is_superuser:
            return True
            
        return user.has_perm(permission)
    
    @classmethod
    def get_object_permissions(cls, user_id: int, obj: Any) -> Dict[str, bool]:
        """
        獲取使用者對特定對象的權限
        
        Args:
            user_id: 使用者 ID
            obj: 要檢查權限的對象
            
        Returns:
            權限字典，包含 'view', 'change', 'delete' 等操作的布爾值
        """
        from django.contrib.auth import get_user_model
        from guardian.shortcuts import get_perms
        
        User = get_user_model()
        
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return {
                'view': False,
                'change': False,
                'delete': False
            }
            
        # 超級使用者具有所有權限
        if user.is_superuser:
            return {
                'view': True,
                'change': True,
                'delete': True
            }
            
        # 獲取使用者對對象的權限
        perms = get_perms(user, obj)
        
        return {
            'view': 'view' in perms or 'view_%s' % obj._meta.model_name in perms,
            'change': 'change' in perms or 'change_%s' % obj._meta.model_name in perms,
            'delete': 'delete' in perms or 'delete_%s' % obj._meta.model_name in perms
        }
    
    @classmethod
    def filter_objects_by_permission(cls, user_id: int, queryset: Any, permission: str) -> Any:
        """
        根據權限過濾查詢集
        
        Args:
            user_id: 使用者 ID
            queryset: 要過濾的查詢集
            permission: 權限字符串 (例如：'view', 'change', 'delete')
            
        Returns:
            過濾後的查詢集
        """
        from django.contrib.auth import get_user_model
        from guardian.shortcuts import get_objects_for_user
        
        User = get_user_model()
        
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return queryset.none()
            
        # 超級使用者可以看到所有對象
        if user.is_superuser:
            return queryset
            
        # 構建完整權限字符串
        model = queryset.model
        app_label = model._meta.app_label
        model_name = model._meta.model_name
        perm_string = f"{app_label}.{permission}_{model_name}"
        
        # 使用 guardian 過濾查詢集
        return get_objects_for_user(user, perm_string, queryset)
    
    @classmethod
    def assign_object_permission(cls, user_id: int, obj: Any, permission: str) -> bool:
        """
        為使用者分配對象權限
        
        Args:
            user_id: 使用者 ID
            obj: 要分配權限的對象
            permission: 權限字符串 (例如：'view', 'change', 'delete')
            
        Returns:
            是否成功分配權限
        """
        from django.contrib.auth import get_user_model
        from guardian.shortcuts import assign_perm
        
        User = get_user_model()
        
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return False
            
        # 構建完整權限字符串
        model = obj._meta.model
        app_label = model._meta.app_label
        model_name = model._meta.model_name
        perm_string = f"{permission}_{model_name}"
        
        # 分配權限
        assign_perm(perm_string, user, obj)
        return True