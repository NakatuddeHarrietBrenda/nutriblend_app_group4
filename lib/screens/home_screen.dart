import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Initial fetch of products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchInitialProducts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Boutique Branding Header
            _buildBoutiqueHeader(),
            
            // Modern Search Field
            _buildSearchField(productProvider),
            
            // Horizontal Category Selector Chips
            if (productProvider.errorMessage.isEmpty && !productProvider.isLoading)
              _buildCategoryBar(productProvider),
              
            // Main Boutique Catalog Area
            Expanded(
              child: _buildCatalogArea(productProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoutiqueHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NUTRIBLEND HAVEN',
                style: TextStyle(
                  color: const Color(0xFFD4AF37).withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Signature Scents',
                style: TextStyle(
                  color: Color(0xFFF5F5F0),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Playfair Display',
                ),
              ),
            ],
          ),
          
          // Subtle Gold Dot Accent
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        onChanged: (value) {
          provider.setSearchQuery(value);
        },
        decoration: InputDecoration(
          hintText: 'Search velvet, oud, brand or sku...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                    FocusScope.of(context).unfocus();
                  },
                  child: const Icon(Icons.clear_rounded, color: Colors.white30, size: 18),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar(ProductProvider provider) {
    final cats = provider.categories;
    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 8, bottom: 14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final cat = cats[index];
          final isSelected = provider.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: CategoryChip(
              label: cat,
              isSelected: isSelected,
              onTap: () {
                provider.setSelectedCategory(cat);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCatalogArea(ProductProvider provider) {
    // Initial Load Shimmer
    if (provider.isLoading && provider.products.isEmpty) {
      return const ProductGridShimmer();
    }

    // Network Errors page
    if (provider.errorMessage.isNotEmpty && provider.products.isEmpty) {
      return _buildErrorState(provider);
    }

    final filtered = provider.filteredProducts;

    // Filter results empty state
    if (filtered.isEmpty) {
      return _buildNoResultsState(provider);
    }

    return Column(
      children: [
        // Main scroll catalog
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return ProductCard(product: filtered[index]);
            },
          ),
        ),

        // Pagination Controls
        if (provider.lastPage > 1 && !provider.isLoading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border(
                top: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous Button
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: provider.currentPage > 1 ? const Color(0xFFD4AF37) : Colors.white24,
                  onPressed: provider.currentPage > 1 
                      ? () {
                          provider.fetchPage(provider.currentPage - 1);
                          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                        }
                      : null,
                ),
                
                // Page Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                  ),
                  child: Text(
                    'Page ${provider.currentPage} of ${provider.lastPage}',
                    style: const TextStyle(
                      color: Color(0xFFF5F5F0),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Next Button
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: provider.currentPage < provider.lastPage ? const Color(0xFFD4AF37) : Colors.white24,
                  onPressed: provider.currentPage < provider.lastPage 
                      ? () {
                          provider.fetchPage(provider.currentPage + 1);
                          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(ProductProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.08),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              'Connection Interrupted',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Playfair Display',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.fetchInitialProducts();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('RETRY CONNECTING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(ProductProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          const Text(
            'No matching fragrance',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Playfair Display',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try altering details of your query or reset filter chips.',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _searchController.clear();
              provider.clearFilters();
            },
            child: const Text(
              'RESET BOUTIQUE FILTERS',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
