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
            page = '/employees'
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
        for key, value in data['items'].items():
            c.execute('SELECT I.number FROM shop.Item I WHERE I.id = %s', [key])
            num = c.fetchone()[0]
            if value > num:
                return JsonResponse({"response": "Na magazynie nie ma wystarczająco dużej liczby produktów"})

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
        c.execute('SELECT O.id, status, location, SUM(price*quantity), date FROM shop.Order O \
                    JOIN shop.Order_item OI ON O.id = OI.id_order \
                    JOIN shop.Item I ON OI.id_item = I.id WHERE id_client = %s '+ option +'\
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
    

def warehouseman(request):
    with connection.cursor() as c:
        c.execute("SELECT O.id, date FROM shop.Order O \
                    JOIN shop.Employee E ON O.id_employee = E.id WHERE E.id = %s AND status = 'Przygotowywane'", [request.session['id']])
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
                    JOIN shop.Employee E ON O.id_employee = E.id WHERE E.id = %s AND status = 'Oczekuje na kuriera'", [request.session['id']])
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


def employees(request):
    with connection.cursor() as c:
        c.execute("SELECT E.id, E.name, E.surname, E.email, COUNT(O.id) FROM shop.Employee E\
                  LEFT JOIN shop.Order O ON E.id = O.id_employee WHERE id_role != 1 GROUP BY E.id ORDER BY E.id")
        employees = c.fetchall()
    return render(request, 'employees.html', {'employees': employees})


def fire(request,):
    id = json.loads(request.body)
    with connection.cursor() as c:
        c.execute("DELETE FROM shop.Employee WHERE id = %s", [id])
    return JsonResponse({"response": "Zwolniono pracownika"})
    

def add_employee(request):
    if request.method == 'GET':
        return render(request, 'add_employee.html')
    
    data = request.POST
    with connection.cursor() as c:
        try:
            c.execute('SELECT register_employee(%s, %s, %s, %s, %s)', [data['name'], data['surname'], data['email'], data['pass'], data['role']])
        except InternalError as e:
            return render(request, 'add_employee.html', {'error': str(e)[0:str(e).find('\n')]})

    return redirect('/employees')
    

def list_items(request):
    match int(request.GET.get('sort')):
        case 0:
            make_sort = ' ORDER BY id'
        case 1:
            make_sort = " ORDER BY name"
        case 2:
            make_sort = " ORDER BY name DESC"
        case 3:
            make_sort = " ORDER BY number"
        case 4:
            make_sort = " ORDER BY number DESC"
        case 5:
            make_sort = " ORDER BY sold"
        case 6:
            make_sort = " ORDER BY sold DESC"

    limit, have = '', ''
    match int(request.GET.get('filter')):
        case 1:
            limit = " LIMIT 1"
        case 2:
            limit = " LIMIT 3"
        case 3:
            have = " HAVING SUM(quantity) > (SELECT AVG(quantity) FROM shop.Order_item)"
        case 4:
            have = " HAVING price > (SELECT AVG(price) FROM shop.Item)"
        case 5:
            have = " HAVING SUM(quantity) > I.number"

    with connection.cursor() as c:
        c.execute("SELECT I.id, name, price, number, COALESCE(SUM(quantity), 0) AS sold FROM shop.Item I LEFT JOIN shop.Order_item OI ON OI.id_item = I.id GROUP BY I.id" + have + make_sort + limit)
        items = c.fetchall()
    return render(request, 'list_items.html', {'items': items})


def add_item(request):  
    if request.method == 'GET':
        return render(request, 'add_item.html')

    data = request.POST
    with connection.cursor() as cursor:
        try:
            cursor.execute("SELECT new_item(%s, %s, %s)", [data['name'], data['price'], data['number']])
        except InternalError as e:
            return render(request, 'add_item.html', {'error': str(e)[0:str(e).find('\n')]})
    return redirect('/list_items?sort=0&filter=0')


def clients(request):
    with connection.cursor() as c:
        c.execute("SELECT * FROM list_clients()")
        clients = c.fetchall()
    return render(request, 'clients.html', {'clients': clients})


def country_item(request):
    with connection.cursor() as c:
        c.execute("SELECT * FROM country_buy_item()")
        country_buy_item = c.fetchall()
    return render(request, 'country_buy_item.html', {'country_buy_item': country_buy_item})


def country_earn(request):
    with connection.cursor() as c:
        c.execute("SELECT * FROM country_stats()")
        country_stats = c.fetchall()
    return render(request, 'country_stats.html', {'country_stats': country_stats})


def documentation(request):
    return render(request, 'documentation.html')
    