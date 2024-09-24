import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


/// https://deadsimplechat.com/blog/flutter-webview-iframe/
///
class BraintreeHtmlWidget extends StatefulWidget {
  final String token;
  final bool isWeb;
  final bool isDesktopBrowser;
  final bool isAndroid;

  const BraintreeHtmlWidget({super.key,  required this.token, required this.isWeb, required this.isDesktopBrowser, required this.isAndroid,  });

  @override
  State<BraintreeHtmlWidget> createState() => _BraintreeWebWidgetState();
}

class _BraintreeWebWidgetState extends State<BraintreeHtmlWidget> {
  late final WebViewController _webViewController;

  void initialize() {
    _webViewController  = WebViewController();
    if (!(widget.isWeb || widget.isDesktopBrowser)){
      _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
      _webViewController.enableZoom(false);
      _webViewController.setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) async {
          if (widget.isAndroid)
            await _webViewController?.runJavaScriptReturningResult('''
                    let meta = document.getElementsByTagName("meta");
                    for(var i=0; i < meta.length; i++){
                      if(meta[i].name == null) continue;
                      if(meta[i].name == 'viewport'){
                        meta[i].innerHTML="<meta name='viewport'  content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>"
                        break;
                      }
                    }
                    ''');
        },
      ));
    }

    // https://github.com/flutter/flutter/issues/52367
    var headersLocal = <String, String>{
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Credentials': 'true'
      };

    _webViewController.loadRequest(
        Uri.dataFromString(
          _loadHTML(widget.token,),
          mimeType: 'text/html'), headers: headersLocal
          );
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 400,
        maxWidth: MediaQuery.of(context).size.width - 120,
      ),
      child: Container(color: Colors.grey, child: WebViewWidget(controller: _webViewController)),

    );
  }
}

String _loadHTML(String tokenizationKey) {
  return '''
      <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1.0, user-scalable=0">
 <script src="https://js.braintreegateway.com/web/dropin/1.43.0/js/dropin.min.js"></script> 
<script src="http://code.jquery.com/jquery-3.2.1.min.js" crossorigin="anonymous"></script>
        </head>
        <body>
<div id="dropin-wrapper">
  <div id="checkout-message"></div>
  <div id="dropin-container"></div>
  <button id="submitbutton">Submit payment</button>
</div>
          <div class="loader"></div>
          <script>
  console.log("building braintree dropin");
  var button = document.querySelector('#submitbutton');
  var checkoutMessage = document.querySelector('#checkout-message');
  button.style.display = "block";
  button.style.visibility = "visible";
  button.style.opacity = "1";
  braintree.dropin.create({
    // Insert your tokenization key here
    authorization: '$tokenizationKey',
    container: '#dropin-container'
  }, function (createErr, instance) {
    console.log("created dropin successfully");
    button.addEventListener('click', function () {
    console.log("button clicked");
      instance.requestPaymentMethod(function (requestPaymentMethodErr, payload) {
        if (requestPaymentMethodErr) {
          checkoutMessage.textContent = 'Error';
        } else {
          checkoutMessage.textContent = 'Payment success';
          console.log(payload);
        }
      });
    });
  });
</script>
        </body>
      </html>
    ''';
}