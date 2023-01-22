from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('login', views.login, name='login'),
    path('register', views.register, name='register'),
    path('products', views.products, name='products'),
    path('products/<int:sort_by>', views.products, name='products'),
    path('logout', views.logout, name='logout'),
    path('items', views.items, name='items'),
    path('order', views.order, name='order'),
    path('order/<int:filter>', views.order, name='order'),
    path('pay', views.pay, name='pay'),
    path('admin', views.admin, name='admin'),
    path('warehouseman', views.warehouseman, name='warehouseman'),
    path('ready', views.ready, name='ready'),
    path('pick_up', views.pick_up, name='pick_up'),
    path('on_the_way', views.on_the_way, name='on_the_way'),
    path('deliver', views.deliver, name='deliver'),
]