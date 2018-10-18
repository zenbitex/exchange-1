var check = (function () {

    // API path
    var path_query_payment = "/api/v2/query_payment";
    var url_root = window.location.origin;

    var idTransaction = {};
    var method = "POST";

    function callAPIPOST(api, dataPost) {
        // reuturn data
        return $.ajax({
            url: url_root + api,
            type: "post",
            data: dataPost,
            success: function (db) {
                return db;
            },
            error: function (er) {
                throw ReferenceError("Error! Connection error, please check your network!");
            }
        })
    }

    var query = location.search.substr(1);
    var result = {};
    query.split("&").forEach(function(part) {
        var item = part.split("=");
        result[item[0]] = decodeURIComponent(item[1]);
    });
    var id = result.payment_id;
    var ak = result.access_key;
    var addr = result.address;

    return {
        id,
        addr,

        getStatusForID: async function () { // idTest
            let e = {};
            e.payment_id = result.payment_id;
            e.access_key = result.access_key;
            // access_key
            let getStatus = await callAPIPOST(path_query_payment, e);
            // let resultSta = await getStatus.json();
            console.log(getStatus);
            return getStatus;
        },

    }
})();

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function QR() {
    // Var check StatusID
    var limitNumberOfSubmissions = 5;   // need to change
    var maxSubmissions = 10;            // need to change
    var timeOut = 30000;                 // delay time of every submission;
    var addr = check.addr;
    var a = check.id;

    var qrcode = new QRCode('payQRcode', {
        text: addr,
        width: 200,
        height: 200,
        colorDark: '#000000',
        colorLight: '#ffffff',
        correctLevel: QRCode.CorrectLevel.H
    });

    // BorderQR
    var cssBd = `margin-left: 100px; margin-right: 100px; padding-top: 50px; padding-bottom: 50px;
        border: 5px solid black;`;

    var bd = document.getElementById('payQRcode');
    // bd.style.cssText = cssBd;

    var ad = document.getElementById('addrPayment');
    ad.setAttribute("value",check.addr);

    // Infor form succesful
    var info = document.createElement('div');
    info.setAttribute("class", "inforStatus alert alert-info");
    info.innerHTML = "<strong>PLEASE!</strong> Use the app to scan this QRCode";

    var st = document.getElementById('st');
    // st.innerHTML = "asdjqwd";
    st.appendChild(info);

    // loop check status
    for (var i = 0; i < maxSubmissions; i++) {
        // Check status
        if (i === 0) await timeout(5000);
        let t = await check.getStatusForID(i+1);
        if(typeof t.message === "string") throw new ReferenceError(t.message);
        if (!t.message.status) throw alert("Fail to check status");

        // console.log("Amount: ",t.amount_received);

        // status code
        // Success
        let success = document.createElement('div');
        success.setAttribute("class", "inforStatus alert alert-success");
        success.innerHTML = `<strong>Done!</strong> Successful transaction! Received: ${t.amount_received} bitcoin.`;
        // Unsent
        let unsent = document.createElement('div');
        unsent.setAttribute("class", "inforStatus alert alert-warning");
        unsent.innerHTML = `<strong>Unsent!</strong> This transaction has not been paid`;
        // Confirming
        let comfirming = document.createElement('div');
        comfirming.setAttribute("class", "inforStatus alert alert-info");
        comfirming.innerHTML = `<strong>Confirming!</strong> This transaction is being confirmed`;
        // Invalid amount
        let invalidAmount = document.createElement('div');
        invalidAmount.setAttribute("class", "inforStatus alert alert-danger");
        invalidAmount.innerHTML = `<strong>Invalid amount!</strong> You have sent an invalid number of coin! Received: ${t.amount_received}`;
        // Too long
        let longTime = document.createElement('div');
        longTime.setAttribute("class", "inforStatus alert alert-danger");
        longTime.innerHTML = `<strong>Over time!</strong> Too long time for tracking this transaction!`;

        console.log("Status: ",t.message.status);
        if (t.message.status === "success") {
            st.removeChild(info);
            let dk = document.getElementById('done');
            dk.appendChild(success);
            break;
        } else if (t.message.status === "invalid amount") { // && i >= limitNumberOfSubmissions
            st.removeChild(info);
            let dk = document.getElementById('done');
            dk.appendChild(invalidAmount);
            break;
        } else if (t.message.status === "confirming") {
            st.removeChild(info);
            let dk = document.getElementById('done');
            dk.appendChild(confirming);
        } else if (t.message.status === "unsent") {
            st.removeChild(info);
            let dk = document.getElementById('done');
            dk.appendChild(unsent);
        }
        // Time out every time
        await timeout(timeOut);
    }
}

