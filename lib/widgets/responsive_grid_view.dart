import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// GridView متجاوب يتكيف مع حجم الشاشة
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final double? mobileAspectRatio;
  final double? tabletAspectRatio;
  final double? desktopAspectRatio;
  final double? largeDesktopAspectRatio;
  final double? mobileSpacing;
  final double? tabletSpacing;
  final double? desktopSpacing;
  final double? largeDesktopSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.mobileAspectRatio,
    this.tabletAspectRatio,
    this.desktopAspectRatio,
    this.largeDesktopAspectRatio,
    this.mobileSpacing,
    this.tabletSpacing,
    this.desktopSpacing,
    this.largeDesktopSpacing,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobileCount: mobileColumns ?? 1,
      tabletCount: tabletColumns ?? 2,
      desktopCount: desktopColumns ?? 3,
      largeDesktopCount: largeDesktopColumns ?? 4,
    );

    final childAspectRatio = ResponsiveHelper.getChildAspectRatio(
      context,
      mobileRatio: mobileAspectRatio ?? 0.8,
      tabletRatio: tabletAspectRatio ?? 0.9,
      desktopRatio: desktopAspectRatio ?? 1.0,
      largeDesktopRatio: largeDesktopAspectRatio ?? 1.1,
    );

    final spacing = ResponsiveHelper.getSpacing(
      context,
      mobileSpacing: mobileSpacing ?? 8.0,
      tabletSpacing: tabletSpacing ?? 12.0,
      desktopSpacing: desktopSpacing ?? 16.0,
      largeDesktopSpacing: largeDesktopSpacing ?? 20.0,
    );

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      padding: padding ?? ResponsiveHelper.getPadding(context),
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: children,
    );
  }
}

/// GridView.builder متجاوب
class ResponsiveGridViewBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final double? mobileAspectRatio;
  final double? tabletAspectRatio;
  final double? desktopAspectRatio;
  final double? largeDesktopAspectRatio;
  final double? mobileSpacing;
  final double? tabletSpacing;
  final double? desktopSpacing;
  final double? largeDesktopSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGridViewBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.mobileAspectRatio,
    this.tabletAspectRatio,
    this.desktopAspectRatio,
    this.largeDesktopAspectRatio,
    this.mobileSpacing,
    this.tabletSpacing,
    this.desktopSpacing,
    this.largeDesktopSpacing,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobileCount: mobileColumns ?? 1,
      tabletCount: tabletColumns ?? 2,
      desktopCount: desktopColumns ?? 3,
      largeDesktopCount: largeDesktopColumns ?? 4,
    );

    final childAspectRatio = ResponsiveHelper.getChildAspectRatio(
      context,
      mobileRatio: mobileAspectRatio ?? 0.8,
      tabletRatio: tabletAspectRatio ?? 0.9,
      desktopRatio: desktopAspectRatio ?? 1.0,
      largeDesktopRatio: largeDesktopAspectRatio ?? 1.1,
    );

    final spacing = ResponsiveHelper.getSpacing(
      context,
      mobileSpacing: mobileSpacing ?? 8.0,
      tabletSpacing: tabletSpacing ?? 12.0,
      desktopSpacing: desktopSpacing ?? 16.0,
      largeDesktopSpacing: largeDesktopSpacing ?? 20.0,
    );

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: padding ?? ResponsiveHelper.getPadding(context),
      shrinkWrap: shrinkWrap,
      physics: physics,
    );
  }
}

/// Container متجاوب مع عرض أقصى
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Decoration? decoration;
  final double? maxWidth;
  final double? maxHeight;
  final AlignmentGeometry? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.maxWidth,
    this.maxHeight,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context);
    final responsiveMaxWidth = maxWidth ?? ResponsiveHelper.getMaxContentWidth(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: responsiveMaxWidth,
        maxHeight: maxHeight ?? double.infinity,
      ),
      padding: responsivePadding,
      margin: margin,
      color: color,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

/// Row متجاوب يتحول إلى Column في الشاشات الصغيرة
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool forceColumn;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.forceColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    if (isMobile || forceColumn) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}

/// Wrap متجاوب مع مسافات متكيفة
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final Axis direction;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;
  final double? spacing;
  final double? runSpacing;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.spacing,
    this.runSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSpacing = spacing ?? ResponsiveHelper.getSpacing(context);
    final responsiveRunSpacing = runSpacing ?? ResponsiveHelper.getSpacing(context);

    return Wrap(
      direction: direction,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      spacing: responsiveSpacing,
      runSpacing: responsiveRunSpacing,
      children: children,
    );
  }
}


