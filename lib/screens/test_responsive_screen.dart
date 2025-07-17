import 'package:flutter/material.dart';
import '../widgets/responsive_widgets.dart';

/// شاشة اختبار النظام المتجاوب
class TestResponsiveScreen extends StatelessWidget {
  const TestResponsiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveHeading('اختبار النظام المتجاوب'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات الجهاز
              _buildDeviceInfo(context),
              
              const ResponsiveVerticalSpace(),
              
              // اختبار النصوص
              _buildTextTests(),
              
              const ResponsiveVerticalSpace(),
              
              // اختبار البطاقات
              _buildCardTests(),
              
              const ResponsiveVerticalSpace(),
              
              // اختبار الشبكة
              _buildGridTests(),
              
              const ResponsiveVerticalSpace(),
              
              // اختبار الأزرار
              _buildButtonTests(),
              
              const ResponsiveVerticalSpace(),
              
              // اختبار القوائم
              _buildListTests(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final screenHeight = ResponsiveHelper.getScreenHeight(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    return ResponsiveCard(
      color: Colors.blue.withOpacity(0.1),
      border: Border.all(color: Colors.blue.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubheading('معلومات الجهاز'),
          const ResponsiveVerticalSpace(),
          ResponsiveBodyText('نوع الجهاز: ${_getDeviceTypeName(deviceType)}'),
          ResponsiveBodyText('عرض الشاشة: ${screenWidth.toInt()}px'),
          ResponsiveBodyText('ارتفاع الشاشة: ${screenHeight.toInt()}px'),
          ResponsiveBodyText('الاتجاه: ${isLandscape ? 'أفقي' : 'عمودي'}'),
        ],
      ),
    );
  }

  Widget _buildTextTests() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubheading('اختبار النصوص'),
          const ResponsiveVerticalSpace(),
          const ResponsiveHeading('عنوان رئيسي'),
          const ResponsiveSubheading('عنوان فرعي'),
          const ResponsiveBodyText('نص عادي - هذا نص تجريبي لاختبار النظام المتجاوب'),
          const ResponsiveCaption('نص صغير - معلومات إضافية'),
          const ResponsiveVerticalSpace(),
          Row(
            children: [
              ResponsiveIcon(Icons.star, color: Colors.orange),
              const ResponsiveHorizontalSpace(),
              const ResponsiveBodyText('أيقونة متجاوبة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardTests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveSubheading('اختبار البطاقات'),
        const ResponsiveVerticalSpace(),
        ResponsiveGridView(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ResponsiveStatCard(
              title: 'إجمالي الطلاب',
              value: '150',
              icon: Icons.people,
              color: Colors.blue,
              subtitle: 'طالب نشط',
            ),
            ResponsiveStatCard(
              title: 'الرحلات اليوم',
              value: '25',
              icon: Icons.directions_bus,
              color: Colors.green,
              subtitle: 'رحلة مكتملة',
            ),
            ResponsiveStatCard(
              title: 'المشرفين',
              value: '12',
              icon: Icons.supervisor_account,
              color: Colors.orange,
              subtitle: 'مشرف متاح',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridTests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveSubheading('اختبار الشبكة'),
        const ResponsiveVerticalSpace(),
        ResponsiveGridView(
          mobileColumns: 2,
          tabletColumns: 3,
          desktopColumns: 4,
          largeDesktopColumns: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(10, (index) => ResponsiveActionCard(
            title: 'إجراء ${index + 1}',
            description: 'وصف الإجراء رقم ${index + 1}',
            icon: Icons.settings,
            color: Colors.purple,
            onTap: () {},
          )),
        ),
      ],
    );
  }

  Widget _buildButtonTests() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubheading('اختبار الأزرار'),
          const ResponsiveVerticalSpace(),
          ResponsiveButtonGroup(
            buttons: [
              ResponsiveElevatedButton(
                onPressed: () {},
                child: const Text('زر رئيسي'),
              ),
              ResponsiveOutlinedButton(
                onPressed: () {},
                child: const Text('زر ثانوي'),
              ),
              ResponsiveTextButton(
                onPressed: () {},
                child: const Text('زر نص'),
              ),
            ],
          ),
          const ResponsiveVerticalSpace(),
          Row(
            children: [
              ResponsiveIconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite),
                backgroundColor: Colors.red.withOpacity(0.1),
                color: Colors.red,
              ),
              const ResponsiveHorizontalSpace(),
              ResponsiveIconButton(
                onPressed: () {},
                icon: const Icon(Icons.share),
                backgroundColor: Colors.blue.withOpacity(0.1),
                color: Colors.blue,
              ),
              const ResponsiveHorizontalSpace(),
              ResponsiveIconButton(
                onPressed: () {},
                icon: const Icon(Icons.bookmark),
                backgroundColor: Colors.green.withOpacity(0.1),
                color: Colors.green,
              ),
            ],
          ),
          const ResponsiveVerticalSpace(),
          ResponsiveWrap(
            children: [
              ResponsiveChip(
                label: const Text('تصنيف 1'),
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
              ResponsiveChip(
                label: const Text('تصنيف 2'),
                backgroundColor: Colors.green.withOpacity(0.1),
              ),
              ResponsiveChip(
                label: const Text('تصنيف 3'),
                backgroundColor: Colors.orange.withOpacity(0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveSubheading('اختبار القوائم'),
        const ResponsiveVerticalSpace(),
        ResponsiveListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(5, (index) => ResponsiveListCard(
            child: ResponsiveListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: ResponsiveIcon(Icons.person, color: Colors.blue),
              ),
              title: ResponsiveBodyText('عنصر القائمة ${index + 1}'),
              subtitle: ResponsiveCaption('وصف العنصر رقم ${index + 1}'),
              trailing: ResponsiveIconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_ios),
                color: Colors.grey,
              ),
              onTap: () {},
            ),
          )),
        ),
      ],
    );
  }

  String _getDeviceTypeName(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 'موبايل';
      case DeviceType.tablet:
        return 'تابلت';
      case DeviceType.desktop:
        return 'سطح المكتب';
      case DeviceType.largeDesktop:
        return 'سطح مكتب كبير';
    }
  }
}

/// Widget لعرض معلومات الاستجابة في الوقت الفعلي
class ResponsiveDebugInfo extends StatelessWidget {
  const ResponsiveDebugInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Debug Info',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getFontSize(context, mobileFontSize: 12),
              ),
            ),
            Text(
              'Device: ${ResponsiveHelper.getDeviceType(context).name}',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveHelper.getFontSize(context, mobileFontSize: 10),
              ),
            ),
            Text(
              'Width: ${ResponsiveHelper.getScreenWidth(context).toInt()}',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveHelper.getFontSize(context, mobileFontSize: 10),
              ),
            ),
            Text(
              'Columns: ${ResponsiveHelper.getGridCrossAxisCount(context)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveHelper.getFontSize(context, mobileFontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
