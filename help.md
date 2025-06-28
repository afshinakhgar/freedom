حتماً! 🙌 اینجا یه راهنمای قدم‌به‌قدم کامل برات نوشتم تا از اسکریپت قدرتمند `vpn-manager.sh` که برات آماده کردم به بهترین شکل استفاده کنی 👇

---

## 🎯 پیش‌نیازها

* یک سرور ایرانی (Client Node) و یک سرور خارجی (Gateway Node).
* دسترسی root یا کاربر sudo.
* اسکریپت `vpn-manager.sh` را در هر دو سرور آپلود کن و مجوز اجرا بده:

```bash
chmod +x vpn-manager.sh
```

---

## ⚙️ نصب سرویس‌ها

### ۱) نصب WireGuard در هر دو سرور

روی هر دو سرور اجرا کن:

```bash
./vpn-manager.sh install-wireguard
```

---

### ۲) نصب OpenVPN در هر دو سرور (در صورت نیاز)

روی هر دو سرور اجرا کن:

```bash
./vpn-manager.sh install-openvpn
```

---

## 🚀 مدیریت سرویس‌ها

### WireGuard

* **شروع:**

```bash
./vpn-manager.sh start-wireguard
```

* **توقف:**

```bash
./vpn-manager.sh stop-wireguard
```

### OpenVPN

* **شروع:**

```bash
./vpn-manager.sh start-openvpn
```

* **توقف:**

```bash
./vpn-manager.sh stop-openvpn
```

---

## 🔄 راه‌اندازی Failover

### فعال‌کردن Failover برای WireGuard

روی سرور ایرانی اجرا کن:

```bash
./vpn-manager.sh setup-failover-wireguard
```

### فعال‌کردن Failover برای OpenVPN

روی سرور ایرانی اجرا کن:

```bash
./vpn-manager.sh setup-failover-openvpn
```

---

## 📊 بررسی وضعیت سرویس‌ها

در هر لحظه وضعیت WireGuard و OpenVPN را ببین:

```bash
./vpn-manager.sh status
```

---

## 📝 نکات مهم

✅ برای تست دستی failover، دستور زیر را بزن:

* WireGuard:

```bash
./vpn-manager.sh run-failover-wireguard
```

* OpenVPN:

```bash
./vpn-manager.sh run-failover-openvpn
```

✅ اسکریپت failover هر ۱ دقیقه یک‌بار توسط کران‌جاب اجرا می‌شود و اگر به PRIMARY سرور وصل نشود، به BACKUP سوییچ می‌کند.

✅ بعد از برگشت دسترسی به PRIMARY، به‌طور خودکار دوباره به PRIMARY سوییچ خواهد کرد.

✅ پیام تغییر وضعیت‌ها به‌صورت تلگرام برایت ارسال می‌شود. برای این کار:

* مقادیر `TG_TOKEN` و `TG_CHAT_ID` را در اسکریپت با مقادیر واقعی خودت جایگزین کن.

---

✅ حالا کل VPNت رو از یک نقطه به‌صورت متمرکز و خودکار مدیریت کن 🎉

---

دوست داری یه فایل `Makefile` هم برای مدیریت همین دستورات بسازم؟

