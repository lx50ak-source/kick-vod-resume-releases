# Kick VOD Resume

إضافة لمتصفح Brave تحفظ مكانك في فيديوهات Kick المسجلة وترجعك له بعد تحديث الصفحة.

## التثبيت (أمر واحد في PowerShell)

```powershell
irm https://raw.githubusercontent.com/lx50ak-source/kick-vod-resume-releases/main/install.ps1 | iex
```

بعدها، أول مرة فقط في Brave: افتح `brave://extensions` ← فعّل **Developer mode** ← **Load unpacked** ← `Ctrl+V` ← **Select Folder**.

- التحديث تلقائي: الملفات تتحدّث وحدها، والنسخة الجديدة تشتغل بعد ما تعيد تشغيل Brave.
- الأمر ما يلمس بيانات Brave نهائياً (الحسابات، السجل، الإضافات الثانية).
