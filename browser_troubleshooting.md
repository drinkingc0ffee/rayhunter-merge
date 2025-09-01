# Browser Troubleshooting for 404 Error

If you're getting a 404 error when trying to access http://localhost:8080/fs/debug_sse_minimal_with_map.html in your browser, but wget can access it successfully, try the following:

## 1. Clear Browser Cache

Your browser might be caching a previous 404 response. Try:
- **Chrome**: Press Ctrl+Shift+Delete (or Cmd+Shift+Delete on Mac), check "Cached images and files", and click "Clear data"
- **Firefox**: Press Ctrl+Shift+Delete (or Cmd+Shift+Delete on Mac), check "Cache", and click "Clear Now"
- **Safari**: Press Cmd+Option+E to clear cache

## 2. Try Incognito/Private Mode

Open a new incognito/private window and try accessing the URL again.

## 3. Try a Different Browser

If you have another browser installed, try accessing the URL there.

## 4. Add a Query Parameter

Try adding a query parameter to force a fresh request:
```
http://localhost:8080/fs/debug_sse_minimal_with_map.html?nocache=1
```

## 5. Check Browser Developer Tools

1. Open browser developer tools (F12 or Ctrl+Shift+I or Cmd+Option+I on Mac)
2. Go to the Network tab
3. Access the URL and look for the request
4. Check the status code and response headers

## 6. Verify Port Forwarding

Run this command to verify port forwarding:
```bash
adb forward --list
```

## 7. Try Direct IP Address

Instead of using localhost, try using the IP address of your computer:
```
http://127.0.0.1:8080/fs/debug_sse_minimal_with_map.html
```

## 8. Check Server Logs

Check if there are any errors in the server logs:
```bash
adb shell rootshell -c "'cat /data/rayhunter/rayhunter.log'"
```

