import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzd;
import 'package:timezone/timezone.dart' as tz;

final kStart = DateTime(2026, 5, 26);
const kPink = Color(0xFFFF2A6D), kGold = Color(0xFFFF9E00);
const kBg1 = Color(0xFF07020A), kBg2 = Color(0xFF170522);
String k(Object v) => v.toString().replaceAllMapped(RegExp(r'\d'), (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)]);
const kM = ['خاکەلێوە','بانەمەڕ','جۆزەردان','پووشپەڕ','گەلاوێژ','خەرمانان','ڕەزبەر','گەڵاڕێزان','سەرماوەز','بەفرانبار','ڕێبەندان','ڕەشەمە'];
const sM = ['فروردین','اردیبهشت','خرداد','تیر','مرداد','شهریور','مهر','آبان','آذر','دی','بهمن','اسفند'];
const hM = ['محرم','صفر','ربیع الأول','ربیع الآخر','جمادى الأولى','جمادى الآخرة','رجب','شعبان','رمضان','شوال','ذو القعدة','ذو الحجة'];
const gM = ['ئانویە','شوبات','ئازار','نیسان','ئایار','حوزەیران','تەمموز','ئاب','ئەیلوول','تشرینی یەکەم','تشرینی دووەم','کانوونی یەکەم'];

List<int> jal(DateTime d) {
  const g = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  var gy = d.year, jy = 0;
  if (gy > 1600) { jy = 979; gy -= 1600; } else { gy -= 621; }
  final gy2 = d.month > 2 ? gy + 1 : gy;
  var days = 365 * gy + (gy2 + 3) ~/ 4 - (gy2 + 99) ~/ 100 + (gy2 + 399) ~/ 400 - 80 + d.day + g[d.month - 1];
  jy += 33 * (days ~/ 12053); days %= 12053;
  jy += 4 * (days ~/ 1461); days %= 1461;
  if (days > 365) { jy += (days - 1) ~/ 365; days = (days - 1) % 365; }
  final jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
  final jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
  return [jy, jm, jd];
}
String kDate(DateTime d) { final j = jal(d); return '${k(j[2])}ی ${kM[j[1] - 1]} ${k(j[0] + 1321)}'; }
List<int> elapsed(DateTime n) {
  if (n.isBefore(kStart)) return List.filled(6, 0);
  var y = n.year - 2026, m = n.month - 5, d = n.day - 26;
  if (d < 0) { m--; d += DateTime(n.year, n.month, 0).day; }
  if (m < 0) { y--; m += 12; }
  return [y, m, d, n.hour, n.minute, n.second];
}

// ---------- notifications: 08:00 every day, next 30 days scheduled with the exact day count
final np = FlutterLocalNotificationsPlugin();
List<String> msgs(String n) => ['ئەمڕۆ $n ڕۆژە پێکەوەین، هاوڕێ و ڕۆژین ❤️', '$n ڕۆژ لە خۆشەویستی، و هێشتا دڵم بۆ تۆ دەلەرزێت 💕', 'بەیانیت باش ڕۆژین، $n ڕۆژە ژیانم بە تۆ جوانە 🌹', 'هاوڕێ، ڕۆژی $n ی ئەفسانەی ئێمەیە ✨'];
Future<void> initNotif() async {
  try {
    tzd.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tehran')); // change if you live in another time zone
    await np.initialize(const InitializationSettings(android: AndroidInitializationSettings('ic_heart_notif')));
    await np.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await np.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    final r = Random();
    for (var i = 0; i < 30; i++) {
      final d = tz.TZDateTime(tz.local, t.year, t.month, t.day + i, 8);
      final n = DateTime(d.year, d.month, d.day).difference(kStart).inDays;
      await np.zonedSchedule(100 + i, 'H ❤ R', msgs(k(n))[r.nextInt(4)], d,
          const NotificationDetails(android: AndroidNotificationDetails('love_daily', 'Daily love message',
              importance: Importance.max, priority: Priority.high, color: kPink, icon: 'ic_heart_notif')),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
    }
  } catch (e) { debugPrint('notif: $e'); }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'H ❤ R',
    theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: kBg1, textTheme: GoogleFonts.vazirmatnTextTheme(ThemeData.dark().textTheme)),
    builder: (c, w) => Directionality(textDirection: TextDirection.rtl, child: w!),
    home: const Home(),
  ));
  initNotif();
}

// ---------- painters
Path heart(Offset c, double s) => Path()
  ..moveTo(c.dx, c.dy + s * .9)
  ..cubicTo(c.dx - s * 1.6, c.dy - s * .1, c.dx - s * .7, c.dy - s * 1.3, c.dx, c.dy - s * .45)
  ..cubicTo(c.dx + s * .7, c.dy - s * 1.3, c.dx + s * 1.6, c.dy - s * .1, c.dx, c.dy + s * .9);

class BgP extends CustomPainter {
  final double t; final List<List<double>> ps;
  BgP(this.t, this.ps);
  @override
  void paint(Canvas cv, Size s) {
    final r = Offset.zero & s;
    cv.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kBg1, kBg2]).createShader(r));
    final a = t * 2 * pi * 6;
    void blob(Color c, double x, double y, double rad) => cv.drawCircle(Offset(s.width * x, s.height * y), rad,
        Paint()..color = c.withOpacity(.24)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90));
    blob(kPink, .2 + .6 * (.5 + .5 * sin(a)), .18, 170);
    blob(const Color(0xFF7B2CBF), .8 - .6 * (.5 + .5 * sin(a * .8)), .55, 200);
    blob(kGold, .5 + .3 * cos(a * .6), .92, 150);
    for (final p in ps) {
      final f = (t * 60 * p[1] + p[3]) % 1;
      final y = (1 - f) * (s.height + 60) - 30, x = p[0] * s.width + sin(t * 2 * pi * 12 + p[3] * 6) * 18;
      final col = (p[3] > .5 ? kPink : kGold).withOpacity(.75 * sin(f * pi));
      if (p[4] > .5) {
        cv.drawPath(heart(Offset(x, y), p[2]), Paint()..color = col..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
        cv.drawPath(heart(Offset(x, y), p[2] * .8), Paint()..color = col);
      } else {
        cv.drawCircle(Offset(x, y), p[2] * .35, Paint()..color = col..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }
    }
  }
  @override
  bool shouldRepaint(BgP o) => true;
}

class HeartP extends CustomPainter {
  final double beat;
  HeartP(this.beat);
  @override
  void paint(Canvas cv, Size s) {
    final c = s.center(Offset.zero), r = s.height * .26 * beat;
    cv.drawPath(heart(c.translate(0, 8), r * 1.2), Paint()..color = kPink.withOpacity(.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36));
    for (var i = 12; i > 0; i--) {
      cv.drawPath(heart(c.translate(0, i * 1.5), r), Paint()..color = Color.lerp(const Color(0xFF4A0724), kPink, 1 - i / 12)!);
    }
    cv.drawPath(heart(c, r), Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF8FB4), kPink, kGold]).createShader(Rect.fromCircle(center: c, radius: r * 1.7)));
    cv.drawPath(heart(c.translate(-r * .38, -r * .42), r * .26), Paint()..color = Colors.white.withOpacity(.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
  }
  @override
  bool shouldRepaint(HeartP o) => o.beat != beat;
}

// ---------- small widgets
class Glass extends StatelessWidget {
  final Widget child;
  const Glass({super.key, required this.child});
  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(.16)),
                gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Colors.white.withOpacity(.13), Colors.white.withOpacity(.04)]),
                boxShadow: [BoxShadow(color: kPink.withOpacity(.12), blurRadius: 30, offset: const Offset(0, 12))],
              ),
              child: child,
            ),
          ),
        ),
      );
}

class Rise extends StatelessWidget {
  final int i; final Widget child;
  const Rise(this.i, this.child, {super.key});
  @override
  Widget build(BuildContext c) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1), duration: Duration(milliseconds: 700 + i * 220), curve: Curves.easeOutCubic,
        builder: (_, v, ch) => Opacity(opacity: v, child: Transform(alignment: Alignment.center, transform: Matrix4.identity()..setEntry(3, 2, .001)..translate(0.0, 50 * (1 - v))..rotateX(.5 * (1 - v)), child: ch)),
        child: child,
      );
}

Widget grad(String t, double sz) => ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [kPink, kGold]).createShader(r), child: Text(t, style: TextStyle(fontSize: sz, fontWeight: FontWeight.w800, color: Colors.white)));

// ---------- home
class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  final pc = PageController(viewportFraction: .72);
  final tc = TextEditingController();
  final rnd = Random(7);
  late final List<List<double>> ps = List.generate(42, (_) => [rnd.nextDouble(), .03 + rnd.nextDouble() * .06, 5 + rnd.nextDouble() * 9, rnd.nextDouble(), rnd.nextDouble()]);
  Timer? tm;
  DateTime now = DateTime.now();
  List<Map<String, dynamic>> items = [];
  String who = 'هاوڕێ';
  String? img;
  double ry = 0;

  @override
  void initState() {
    super.initState();
    tm = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => now = DateTime.now()));
    _load();
  }
  @override
  void dispose() { tm?.cancel(); c.dispose(); pc.dispose(); tc.dispose(); super.dispose(); }

  Future<void> _load() async {
    final s = (await SharedPreferences.getInstance()).getString('hr_diary_v1');
    if (s != null) setState(() => items = (jsonDecode(s) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
  }
  Future<void> _persist() async => (await SharedPreferences.getInstance()).setString('hr_diary_v1', jsonEncode(items));
  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 82);
    if (x == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final p = '${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(x.path).copy(p);
    setState(() => img = p);
  }
  Future<void> _save() async {
    final t = tc.text.trim();
    if (t.isEmpty && img == null) return;
    final ms = DateTime.now().millisecondsSinceEpoch;
    items.add({'id': ms, 't': ms, 'who': who, 'txt': t, 'img': img ?? ''});
    await _persist();
    tc.clear();
    setState(() => img = null);
  }
  Future<void> _del(Map<String, dynamic> e) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(content: const Text('دڵنیایت؟'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('نەخێر')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بەڵێ'))]));
    if (ok != true) return;
    if ((e['img'] ?? '') != '') { try { await File(e['img']).delete(); } catch (_) {} }
    items.remove(e);
    await _persist();
    setState(() {});
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: AnimatedBuilder(animation: c, builder: (_, __) => CustomPaint(painter: BgP(c.value, ps)))),
        SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 60), children: [Rise(0, _hero()), Rise(1, _cal()), Rise(2, _gallery()), Rise(3, _form()), Rise(4, _timeline())])),
      ]),
    );
  }

  Widget _name(String n) => Column(children: [const Text('👑', style: TextStyle(fontSize: 30)), Text(n, style: const TextStyle(color: kGold, fontWeight: FontWeight.w800, fontSize: 17, shadows: [Shadow(color: kGold, blurRadius: 14)]))]);
  Widget _box(String l, int v) => Expanded(child: Container(margin: const EdgeInsets.all(4), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)), child: Column(children: [Text(k(v), style: const TextStyle(color: kGold, fontSize: 22, fontWeight: FontWeight.w800)), Text(l, style: const TextStyle(color: Colors.white60, fontSize: 11))])));

  Widget _hero() {
    final el = elapsed(now);
    final days = now.isBefore(kStart) ? 0 : now.difference(kStart).inDays;
    return Glass(child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_name('هاوڕێ'), _name('ڕۆژین')]),
      SizedBox(
        height: 220,
        child: GestureDetector(
          onHorizontalDragUpdate: (d) => setState(() => ry = (ry + d.delta.dx * .012).clamp(-1.2, 1.2).toDouble()),
          onHorizontalDragEnd: (_) => setState(() => ry = 0),
          child: AnimatedBuilder(animation: c, builder: (_, __) {
            final s = c.value * 60;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ry), duration: const Duration(milliseconds: 180),
              builder: (_, v, __) => Transform(alignment: Alignment.center, transform: Matrix4.identity()..setEntry(3, 2, .0012)..rotateY(v + sin(s * 1.2) * .35), child: CustomPaint(size: const Size(double.infinity, 220), painter: HeartP(1 + .05 * sin(s * 5)))),
            );
          }),
        ),
      ),
      grad('ڕۆژنامەی هەتاهەتایی ژیان', 22),
      const SizedBox(height: 6),
      Text(k(days), style: const TextStyle(fontSize: 68, fontWeight: FontWeight.w800, color: kPink, shadows: [Shadow(color: kPink, blurRadius: 30)])),
      const Text('ڕۆژ پێکەوە ❤', style: TextStyle(color: Colors.white60)),
      const SizedBox(height: 10),
      Row(children: [_box('ساڵ', el[0]), _box('مانگ', el[1]), _box('ڕۆژ', el[2])]),
      Row(children: [_box('کاتژمێر', el[3]), _box('خولەک', el[4]), _box('چرکە', el[5])]),
    ]));
  }

  Widget _h(String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: const TextStyle(color: kGold, fontSize: 18, fontWeight: FontWeight.w800)));

  Widget _cal() {
    final p = jal(kStart), h = HijriCalendar.fromDate(kStart);
    final rows = [
      ['ساڵنامەی کوردی', '${k(p[2])}ی ${kM[p[1] - 1]} ${k(p[0] + 1321)}'],
      ['هەتاوی (شمسی)', '${k(p[2])} ${sM[p[1] - 1]} ${k(p[0])}'],
      ['هیجری مانگی', '${k(h.hDay)} ${hM[h.hMonth - 1]} ${k(h.hYear)}'],
      ['زایینی', '${k(kStart.day)}ی ${gM[kStart.month - 1]} ${k(kStart.year)}'],
    ];
    return Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h('⌁ چوار ساڵنامە'),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.9, mainAxisSpacing: 8, crossAxisSpacing: 8, children: [
        for (final r in rows) Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(r[0], style: const TextStyle(color: kPink, fontSize: 12, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(r[1], style: const TextStyle(fontSize: 13))])),
      ]),
    ]));
  }

  Widget _ph(int i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24), gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF3A0B4D), Color(0x99FF2A6D)])),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🌹', style: TextStyle(fontSize: 46)), const SizedBox(height: 8), Text('وێنەی ${k(i)}', style: const TextStyle(color: Colors.white70))]),
      );
  Widget _photo(Map<String, dynamic> e) {
    final d = DateTime.fromMillisecondsSinceEpoch(e['t']);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24), boxShadow: [BoxShadow(color: kPink.withOpacity(.3), blurRadius: 24)]),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(fit: StackFit.expand, children: [
        Image.file(File(e['img']), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black26)),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])), child: Text('${e['who']} · ${kDate(d)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)))),
      ])),
    );
  }

  Widget _gallery() {
    final sl = <Widget>[for (var i = 1; i <= 9; i++) _ph(i), for (final e in items) if ((e['img'] ?? '') != '') _photo(e)];
    return Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h('✦ گاڵەری وێنەکان'),
      SizedBox(height: 340, child: PageView.builder(controller: pc, itemCount: sl.length, itemBuilder: (_, i) => AnimatedBuilder(
        animation: pc,
        builder: (_, ch) {
          var v = 1.0;
          if (pc.hasClients && pc.position.haveDimensions) v = (1 - (pc.page! - i).abs() * .22).clamp(.78, 1.0).toDouble();
          return Center(child: Transform.scale(scale: v, child: ch));
        },
        child: sl[i],
      ))),
    ]));
  }

  Widget _form() => Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _h('＋ بیرەوەرییەکی نوێ'),
        Wrap(spacing: 8, children: [for (final n in ['هاوڕێ', 'ڕۆژین']) ChoiceChip(label: Text(n), selected: who == n, selectedColor: kPink, onSelected: (_) => setState(() => who = n))]),
        const SizedBox(height: 10),
        TextField(controller: tc, minLines: 3, maxLines: 6, decoration: InputDecoration(hintText: 'نامەیەکی خۆشەویستی بنووسە…', filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
        const SizedBox(height: 10),
        if (img != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(img!), height: 120, width: double.infinity, fit: BoxFit.cover)),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _pick, icon: const Icon(Icons.photo_library_outlined), label: const Text('وێنە'))),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: kPink, padding: const EdgeInsets.all(14)), onPressed: _save, child: const Text('پاشەکەوت بکە ❤', style: TextStyle(fontWeight: FontWeight.w800)))),
        ]),
      ]));

  Widget _timeline() => Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _h('ڕۆژنامەی ژیان'),
        if (items.isEmpty) const Text('هێشتا هیچ نییە… یەکەم بیرەوەری بنووسە ❤', style: TextStyle(color: Colors.white54)),
        for (final e in items.reversed) _entry(e),
      ]));

  Widget _entry(Map<String, dynamic> e) {
    final d = DateTime.fromMillisecondsSinceEpoch(e['t']);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(18), border: const Border(right: BorderSide(color: kPink, width: 3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(e['who'], style: const TextStyle(color: kPink, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Expanded(child: Text('${kDate(d)} · ${k(d.hour)}:${k(d.minute.toString().padLeft(2, '0'))}', style: const TextStyle(color: Colors.white54, fontSize: 12))),
          IconButton(visualDensity: VisualDensity.compact, onPressed: () => _del(e), icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white38)),
        ]),
        if ((e['img'] ?? '') != '') Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(e['img']), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()))),
        if ((e['txt'] ?? '') != '') Text(e['txt'], style: const TextStyle(height: 1.7)),
      ]),
    );
  }
}
