function getCookie(cname) {
    let name = cname + "=";
    let decodedCookie = decodeURIComponent(document.cookie);
    let ca = decodedCookie.split(';');
    for (let i = 0; i < ca.length; i++) {
        let c = ca[i];
        while (c.charAt(0) == ' ') {
            c = c.substring(1);
        }
        if (c.indexOf(name) == 0) {
            return c.substring(name.length, c.length);
        }
    }
    return "";
}


var itemsList = {};

function addItem(id) {
    if (id in itemsList) itemsList[id] += 1;
    else itemsList[id] = 1;
    var item = document.getElementById('item-' + id);
    if (parseInt(item.innerHTML) != 0) item.innerHTML = parseInt(item.innerHTML) - 1

    var node = document.getElementById('cart').getElementsByTagName('tbody')[0];
    const newNode = document.createElement("tr");
    var info = item.parentElement.childNodes;
    newNode.innerHTML = "<td>" + info[1].textContent + "</td>\
                        <td>"+ info[5].textContent + "</td>";
    node.appendChild(newNode);
}

function order(event) {
    event.preventDefault();

    if(Object.keys(itemsList).length == 0) {
        alert('Wybierz produkt');
        return;
    }
    var location = document.getElementById('adress').value;
    fetch('/items', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCookie("csrftoken") },
        body: JSON.stringify({'items': itemsList, 'location': location})
    }).then(res => res.json()).then(data => {
        document.getElementById('cart').getElementsByTagName('tbody')[0].innerHTML = '';
        itemsList = {};
        alert(data.response);
        window.location.href = '/products';
    })
    .catch(error => console.error('Error:', error));
}


function pay(order_id) {
    fetch('/pay', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCookie("csrftoken") },
        body: JSON.stringify(order_id)
    }).then(res => res.json()).then(data => {
        alert(data.response);
        window.location.href = '/pay';
    })
    .catch(error => console.error('Error:', error));
}


function ready(id) {
    fetch('/ready', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCookie("csrftoken") },
        body: JSON.stringify(id)
    }).then(res => res.json()).then(data => {
        alert(data.response);
        window.location.href = '/warehouseman';
    })
    .catch(error => console.error('Error:', error));
}


function pick_up(id) {
    fetch('/pick_up', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCookie("csrftoken") },
        body: JSON.stringify(id)
    }).then(res => res.json()).then(data => {
        alert(data.response);
        window.location.href = '/pick_up';
    })
    .catch(error => console.error('Error:', error));
}


function deliver(id) {
    fetch('/deliver', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCookie("csrftoken") },
        body: JSON.stringify(id)
    }).then(res => res.json()).then(data => {
        alert(data.response);
        window.location.href = '/on_the_way';
    })
    .catch(error => console.error('Error:', error));
}


function fire(id) {
    fetch('/fire', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCookie("csrftoken") },
        body: JSON.stringify(id)
    }).then(res => res.json()).then(data => {
        alert(data.response);
        window.location.href = '/employees';
    }).catch(error => console.error('Error:', error));
}


function list_items(type, option) {
    var url = window.location.href;
    if(type == "sort") window.location.href = url.replace(/sort=\d+/, "sort="+option);
    else window.location.href = url.replace(/filter=\d+/, "filter="+option);
}