import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/organization_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/organization_model.dart';
import '../../core/api/api_exception.dart';

class OrganizationsScreen extends ConsumerStatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  ConsumerState<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends ConsumerState<OrganizationsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddOrganizationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddOrganizationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final orgsAsync = ref.watch(organizationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(organizationsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Header Bar ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Builder(
                            builder: (scaffoldCtx) => GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Scaffold.of(scaffoldCtx).openDrawer(),
                              child: InitialsAvatar(
                                name: user?.name ?? 'Super Admin',
                                radius: 22,
                                showRing: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Organizations',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      'SuperAdmin',
                                      style: TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Manage all businesses & workspaces',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary(context),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _openAddOrganizationSheet(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                        tooltip: 'Add Organization',
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search & Filter ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search organization, email, or website...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary(context),
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface(context),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide(
                          color: AppColors.separator(context),
                          width: 0.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide(
                          color: AppColors.separator(context),
                          width: 0.5,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim().toLowerCase());
                    },
                  ),
                ),
              ),

              // ── Async Content ───────────────────────────────────────────
              orgsAsync.when(
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: List.generate(
                        3,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: SurfaceCard(
                            child: const SkeletonRow(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Failed to load organizations',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary(context),
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                            ),
                            onPressed: () => ref.invalidate(organizationsProvider),
                            icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                            label: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (orgs) {
                  final filtered = orgs.where((org) {
                    if (_searchQuery.isEmpty) return true;
                    final name = org.name.toLowerCase();
                    final email = (org.contactEmail ?? '').toLowerCase();
                    final phone = (org.contactPhone ?? '').toLowerCase();
                    final website = (org.websiteUrl ?? '').toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery) ||
                        phone.contains(_searchQuery) ||
                        website.contains(_searchQuery);
                  }).toList();

                  final totalCount = orgs.length;
                  final activeCount = orgs.where((o) => o.isActive).length;

                  return SliverMainAxisGroup(
                    slivers: [
                      // ── Metrics Strip ──────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatSummaryCard(
                                  title: 'Total Businesses',
                                  value: '$totalCount',
                                  icon: Icons.business_rounded,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _StatSummaryCard(
                                  title: 'Active Businesses',
                                  value: '$activeCount',
                                  icon: Icons.check_circle_outline_rounded,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── List Section ───────────────────────────────────
                      if (filtered.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xxl,
                            ),
                            child: EmptyStateWidget(
                              icon: Icons.domain_disabled_rounded,
                              title: _searchQuery.isEmpty
                                  ? 'No organizations yet'
                                  : 'No matching organizations',
                              subtitle: _searchQuery.isEmpty
                                  ? 'Tap "+ Add Organization" to register your first business.'
                                  : 'Try changing your search terms.',
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.xs,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final org = filtered[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: StaggeredItem(
                                    index: index,
                                    child: _OrganizationCard(organization: org),
                                  ),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: () => _openAddOrganizationSheet(context),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Business', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary(context),
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Organization Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _OrganizationCard extends StatelessWidget {
  final OrganizationModel organization;

  const _OrganizationCard({required this.organization});

  @override
  Widget build(BuildContext context) {
    final createdStr = organization.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(organization.createdAt!)
        : null;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Title Row ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.projectColor(organization.id),
                      AppColors.projectColor(organization.id).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Center(
                  child: Text(
                    organization.name.isNotEmpty
                        ? organization.name.substring(0, 1).toUpperCase()
                        : 'O',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                    if (createdStr != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Registered: $createdStr',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary(context),
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: organization.isActive
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: organization.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      organization.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: organization.isActive
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          const AppDivider(),
          const SizedBox(height: AppSpacing.sm),

          // ── Contact Information ─────────────────────────────────────────
          if (organization.contactEmail != null &&
              organization.contactEmail!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.email_outlined,
              label: organization.contactEmail!,
              onTap: () async {
                final uri = Uri(scheme: 'mailto', path: organization.contactEmail);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            const SizedBox(height: 6),
          ],

          if (organization.contactPhone != null &&
              organization.contactPhone!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.phone_outlined,
              label: organization.contactPhone!,
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: organization.contactPhone);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            const SizedBox(height: 6),
          ],

          if (organization.websiteUrl != null &&
              organization.websiteUrl!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.language_rounded,
              label: organization.websiteUrl!,
              isLink: true,
              onTap: () async {
                var url = organization.websiteUrl!;
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  url = 'https://$url';
                }
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 6),
          ],

          if (organization.address != null &&
              organization.address!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: organization.address!,
            ),
            const SizedBox(height: 6),
          ],

          // ── Counts summary badge row ────────────────────────────────────
          const SizedBox(height: 4),
          Row(
            children: [
              _CountBadge(
                label: 'Users',
                count: organization.userCount,
                icon: Icons.people_outline,
              ),
              const SizedBox(width: 8),
              _CountBadge(
                label: 'Projects',
                count: organization.projectCount,
                icon: Icons.folder_open_rounded,
              ),
              const SizedBox(width: 8),
              _CountBadge(
                label: 'Offices',
                count: organization.geofenceCount,
                icon: Icons.location_city_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLink;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isLink ? AppColors.accent : AppColors.textPrimary(context),
                    fontWeight: isLink ? FontWeight.w500 : FontWeight.w400,
                    decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: AppColors.textTertiary(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _CountBadge({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary(context)),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: AppColors.textSecondary(context),
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Organization Modal Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddOrganizationSheet extends ConsumerStatefulWidget {
  const _AddOrganizationSheet();

  @override
  ConsumerState<_AddOrganizationSheet> createState() => _AddOrganizationSheetState();
}

class _AddOrganizationSheetState extends ConsumerState<_AddOrganizationSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final request = CreateOrganizationRequest(
      name: _nameCtrl.text.trim(),
      contactEmail: _contactEmailCtrl.text.trim(),
      adminName: _adminNameCtrl.text.trim(),
      adminEmail: _adminEmailCtrl.text.trim(),
      adminPassword: _adminPassCtrl.text,
    );

    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.createOrganization(request);

    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        ref.invalidate(organizationsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Organization "${request.name}" created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case ApiError(exception: final ex):
        setState(() {
          _isLoading = false;
          _errorMessage = ex.message;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle / Header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.separator(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 16, AppSpacing.md, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Business',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Register organization and initial admin',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const AppDivider(),

          // ── Form Scroll Body ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                bottomInset + AppSpacing.md,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message alert banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // ── SECTION: Organization Details ───────────────────
                    _SectionTitle(
                      title: 'BUSINESS INFORMATION',
                      icon: Icons.business_rounded,
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Organization / Business Name *',
                        hintText: 'e.g. ADDONSHAREWARE',
                        prefixIcon: Icon(Icons.apartment_rounded),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Business name is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    TextFormField(
                      controller: _contactEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email *',
                        hintText: 'e.g. contact@addonshareware.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Contact email is required';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── SECTION: Initial Org Admin ──────────────────────
                    _SectionTitle(
                      title: 'INITIAL ORGANIZATION ADMIN',
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    TextFormField(
                      controller: _adminNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Admin Full Name *',
                        hintText: 'e.g. John Doe',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Admin name is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    TextFormField(
                      controller: _adminEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Admin Email *',
                        hintText: 'e.g. admin@addonshareware.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Admin email is required';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    TextFormField(
                      controller: _adminPassCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Admin Password *',
                        hintText: 'Initial login password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Password is required';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Submit Button ───────────────────────────────────
                    PremiumButton(
                      label: 'Create Organization',
                      loading: _isLoading,
                      loadingLabel: 'Creating organization...',
                      useGradient: true,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
