import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class CustomerSearchHeader extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilter;
  final VoidCallback onAddCustomer;
  final bool isAdmin;
  final bool hasActiveFilters;

  const CustomerSearchHeader({
    super.key,
    required this.onSearchChanged,
    required this.onOpenFilter,
    required this.onAddCustomer,
    required this.isAdmin,
    this.hasActiveFilters = false,
  });

  @override
  State<CustomerSearchHeader> createState() => _CustomerSearchHeaderState();
}

class _CustomerSearchHeaderState extends State<CustomerSearchHeader> {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  void _onQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 550;

    final searchField = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onQueryChanged,
        decoration: InputDecoration(
          hintText: 'Search by name, phone, address...',
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearchChanged('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );

    final filterButton = Stack(
      children: [
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: widget.hasActiveFilters ? AppColors.primary : Colors.grey.shade200),
            ),
            minimumSize: const Size(48, 48),
          ),
          icon: Icon(
            Icons.tune_rounded,
            color: widget.hasActiveFilters ? AppColors.primary : AppColors.textSecondary,
          ),
          onPressed: widget.onOpenFilter,
          tooltip: 'Filter & Sort',
        ),
        if (widget.hasActiveFilters)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );

    if (isNarrow) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 8),
              filterButton,
            ],
          ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Add New Customer',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: widget.onAddCustomer,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 10),
        filterButton,
        if (widget.isAdmin) ...[
          const SizedBox(width: 10),
          CustomButton(
            label: 'Add Customer',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: widget.onAddCustomer,
          ),
        ],
      ],
    );
  }
}
