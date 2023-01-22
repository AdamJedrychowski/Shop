from django.shortcuts import render, redirect
from django.db import connection, InternalError
import json
from django.http import JsonResponse
from itertools import groupby
from django.template.defaulttags import register

@register.filter
def get_item(dictionary, key):
    return dictionary.get(key)


def index(request):
    return render(request, 'index.html')


def login(request):
    if request.method == 'GET':
        return render(request, 'login.html')

    data = request.POST
    with connection.cursor() as cursor:
        try:
            cursor.execute('SELECT id, role FROM authenticate(%s, %s)', [data['email'], data['password']])
            row = cursor.fetchone()
            request.session['id'] = row[0]
            request.session['role'] = row[1]
        except InternalError as e:
            return render(request, 'login.html', {'error': str(e)[0:str(e).find('\n')]})
    
    match row[1]:
        case 'Klient':
            page = '/products'
        case 'Admin':
            page = '/admin'
        case 'Magazynier':
            page = '/warehouseman'
        case 'Dostawca':
            page ='/pick_up'

    return redirect(page)


def register(request):
    if request.method == 'GET':
        return render(request, 'register.html')
    else:
        data = request.POST
        with connection.cursor() as c:
            try:
                c.execute('SELECT register_client(%s, %s, %s, %s, %s, %s, %s)', [data['name'], data['surname'], data['email'], data['pass'], data['age'], data.get('gender'), data['country']])
            except InternalError as e:
                return render(request, 'register.html', {'error': str(e)[0:str(e).find('\n')]})
    return redirect('/login')



def products(request, sort_by=0):
    match sort_by:
        case 0:
            option = ''
        case 1:
            option = ' ORDER BY name'
        case 2:
            option = ' ORDER BY name DESC'
        case 3:
            option = ' ORDER BY number'
        case 4:
            option = ' ORDER BY number DESC'
        case 5:
            option = ' ORDER BY price'
        case 6:
            option = ' ORDER BY price DESC'

    with connection.cursor() as cursor:
        cursor.execute('SELECT name, number, price, id FROM shop.Item' + option)
        rows = cursor.fetchall()
    return render(request, 'products.html', {"table": rows})


def items(request):
    data = json.loads(request.body)
    with connection.cursor() as c:
        c.execute('INSERT INTO shop.Order (location, id_client) VALUES (%s, %s) RETURNING id', [data['location'], request.session['id']])
        id = c.fetchone()
        for key, value in data['items'].items():
            c.execute('INSERT INTO shop.Order_item (id_order, id_item, quantity) VALUES (%s, %s, %s)', [id, key, value])

    return JsonResponse({"response": "Zamówienie zapisane"})


def logout(request):
    del request.session['id']
    del request.session['role']
    return redirect('/')


def select_orders(filter, id):
    match filter:
        case 0:
            option = ''
        case 1:
            option = "AND status = 'Nie opłacone' "
        case 2:
            option = "AND status = 'Przygotowywane' "
        case 3:
            option = "AND status = 'Oczekuje na kuriera' "
        case 4:
            option = "AND status = 'W drodze' "
        case 5:
            option = "AND status = 'Dostarczone' "

    with connection.cursor() as c:
        c.execute('SELECT O.id, status, location, SUM(price), date FROM shop.Order O \
                    JOIN shop.Order_item OI ON O.id = OI.id_order \
                    JOIN shop.Item I ON OI.id_item = I.id WHERE id_client = %s '+ option +'\
                    GROUP BY O.id', [id])
        rows = c.fetchall()
    return rows


def select_orders_employee_id(filter, id):
    match filter:
        case 0:
            option = "AND status = 'Przygotowywane' "
        case 1:
            option = "AND status = 'Oczekuje na kuriera' "
        case 2:
            option = "AND status = 'W drodze' "
        case 3:
            option = "AND status = 'Dostarczone' "

    with connection.cursor() as c:
        c.execute('SELECT O.id, date FROM shop.Order O \
                    JOIN shop.Employee E ON O.id_employee = E.id WHERE E.id = %s '+ option +'\
                    GROUP BY O.id', [id])
        rows = c.fetchall()
    return rows
    

def pay(request):
    if request.method == 'GET':
        rows = select_orders(1, request.session['id'])
        return render(request, 'pay.html', {'table': rows})
    data = json.loads(request.body)
    with connection.cursor() as c:
        c.execute("UPDATE shop.Order SET status = 'Przygotowywane' WHERE id = %s", [data])
    return JsonResponse({"response": "Zamówienie opłacone"})
    


def order(request, filter=0):
    rows = select_orders(filter, request.session['id'])
    return render(request, 'orders.html', {'table': rows})


def admin(request):
    return render(request, 'admin.html')
    

def warehouseman(request):
    with connection.cursor() as c:
        c.execute("SELECT O.id, date FROM shop.Order O \
                    JOIN shop.Employee E ON O.id_employee = E.id WHERE E.id = %s AND status = 'Przygotowywane' \
                    GROUP BY O.id", [request.session['id']])
        order = c.fetchall()

        c.execute("SELECT OI.id_order, name, quantity FROM shop.Order_item OI\
                    JOIN shop.Item I ON OI.id_item = I.id\
                    JOIN shop.Order O ON O.id = OI.id_order WHERE id_employee = %s", [request.session['id']])
        items = c.fetchall()

    items_dict = {key: [[i[1], i[2]] for i in group] for key, group in groupby(items, lambda x: x[0])}
    return render(request, 'warehouseman.html', {'orders': order, 'items': items_dict})


def pick_up(request):
    if request.method == 'POST':
        id = json.loads(request.body)
        with connection.cursor() as c:
            c.execute("UPDATE shop.Order SET status = 'W drodze' WHERE id = %s", [id])
        return JsonResponse({"response": "Przesyłka odebrana"})

    with connection.cursor() as c:
        c.execute("SELECT O.id, date, date + INTERVAL '5 days' FROM shop.Order O \
                    JOIN shop.Employee E ON O.id_employee = E.id WHERE E.id = %s AND status = 'Oczekuje na kuriera' \
                    GROUP BY O.id", [request.session['id']])
        order = c.fetchall()

    return render(request, 'pick_up.html', {'orders': order})


def on_the_way(request):
    with connection.cursor() as c:
        c.execute("SELECT O.id, C.name, C.surname, C.email, date, location FROM shop.Order O \
                    JOIN shop.Employee E ON O.id_employee = E.id \
                    JOIN shop.Client C ON C.id = O.id_client WHERE E.id = %s AND status = 'W drodze'", [request.session['id']])
        order = c.fetchall()

    return render(request, 'on_the_way.html', {'orders': order})


def ready(request):
    data = json.loads(request.body)
    with connection.cursor() as c:
        c.execute("UPDATE shop.Order SET status = 'Oczekuje na kuriera' WHERE id = %s", [data])
    return JsonResponse({"response": "Zamówienie przekazane do dostawcy"})


def deliver(request):
    data = json.loads(request.body)
    with connection.cursor() as c:
        c.execute("UPDATE shop.Order SET status = 'Dostarczone' WHERE id = %s", [data])
    return JsonResponse({"response": "Zamówienie przekazane klientowi"})