import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/certificates_provider.dart';
import '../certificates/certificate_detail_screen.dart';

class RecipientHomeScreen extends StatelessWidget {
  const RecipientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final certsProvider = Provider.of<CertificatesProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => certsProvider.loadCertificates(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  onChanged: certsProvider.setSearchQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search certificates...',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Cloud', 'Data', 'Engineering', 'Leadership'].map((cat) {
                    final isSelected = certsProvider.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                        selectedColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                        onSelected: (_) => certsProvider.setCategory(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Credentials', style: AppTypography.headlineMd(isDark)),
                  Text('${certsProvider.filteredCertificates.length} credentials',
                      style: AppTypography.labelSm(isDark)),
                ],
              ),
              const SizedBox(height: 16),

              // Certificate Cards List
              if (certsProvider.filteredCertificates.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.outlineLight),
                        const SizedBox(height: 12),
                        Text('No certificates found', style: AppTypography.headlineSm(isDark)),
                        const SizedBox(height: 6),
                        Text('Try adjusting your search terms or filters.', style: AppTypography.bodyMd(isDark)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: certsProvider.filteredCertificates.length,
                  itemBuilder: (context, index) {
                    final cert = certsProvider.filteredCertificates[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CertificateDetailScreen(certificate: cert),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                      (cert.organizationName ?? 'G')[0],
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cert.organizationName ?? 'Global Tech Institute',
                                          style: AppTypography.bodyLg(isDark).copyWith(fontSize: 14),
                                        ),
                                        Text(
                                          'Issued ${cert.issueDate}',
                                          style: AppTypography.labelSm(isDark).copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cert.isClaimed
                                          ? AppColors.verifiedGreenBg
                                          : AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 14,
                                          color: cert.isClaimed ? AppColors.verifiedGreen : AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          cert.status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: cert.isClaimed ? AppColors.verifiedGreen : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(cert.title, style: AppTypography.headlineSm(isDark)),
                              const SizedBox(height: 8),
                              Text(
                                cert.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMd(isDark),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ID: ${cert.certificateNumber}',
                                    style: AppTypography.hashMono(
                                      color: isDark ? AppColors.cyanAccent : AppColors.primary,
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      size: 14, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
