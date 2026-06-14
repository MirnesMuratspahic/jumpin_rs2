import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jumpin_admin/layouts/master_screen.dart';
import 'package:jumpin_admin/models/review.dart';
import 'package:jumpin_admin/models/search_result.dart';
import 'package:jumpin_admin/providers/review_provider.dart';
import 'package:jumpin_admin/providers/helper_providers/utils.dart';
import 'package:jumpin_admin/widgets/detail_dialog.dart';

class ReviewListScreen extends StatefulWidget {
  const ReviewListScreen({super.key});

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  late ReviewProvider _reviewProvider;
  SearchResult<Review>? _reviewsResult;
  bool _isLoading = true;

  int _currentPage = 1;
  int _pageSize = 50;
  final List<int> _pageSizeOptions = [50, 100, 200];

  @override
  void initState() {
    super.initState();
    _reviewProvider = context.read<ReviewProvider>();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      var filter = <String, dynamic>{
        'Page': _currentPage,
        'PageSize': _pageSize,
      };

      var result = await _reviewProvider.get(filter: filter);

      if (mounted) {
        setState(() {
          _reviewsResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reviews: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Reviews',
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildReviewTable()),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFF9A825), size: 24),
          const SizedBox(width: 10),
          const Text(
            'Review Moderation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
          const Spacer(),
          Text(
            'Total: ${_reviewsResult?.count ?? 0} reviews',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(130, 45),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _loadReviews,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: DropdownButton<int>(
              value: _pageSize,
              underline: const SizedBox(),
              items: _pageSizeOptions.map((size) {
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text('$size per page', style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _pageSize = value;
                    _currentPage = 1;
                    _loadReviews();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTable() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
      );
    }

    final reviews = _reviewsResult?.result;
    if (reviews == null || reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No reviews found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF0D47A1).withOpacity(0.05)),
              columnSpacing: 32,
              horizontalMargin: 24,
              columns: const [
                DataColumn(label: Text('Reviewer Email', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1), fontSize: 13))),
                DataColumn(label: Text('Reviewed User Email', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1), fontSize: 13))),
                DataColumn(label: Text('Rating', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1), fontSize: 13))),
                DataColumn(label: Text('Comment', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1), fontSize: 13))),
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1), fontSize: 13))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1), fontSize: 13))),
              ],
              rows: reviews.map((review) => _buildReviewRow(review)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildReviewRow(Review review) {
    return DataRow(
      cells: [
        DataCell(Text(review.reviewerEmail ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(review.reviewedUserEmail ?? '-')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildStarRating(review.rating ?? 0),
          ),
        ),
        DataCell(
          SizedBox(
            width: 280,
            child: Text(
              review.comment ?? '-',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        DataCell(Text(formatDate(review.createdAt))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Color(0xFF0D47A1), size: 20),
                tooltip: 'View Full Review',
                onPressed: () => _showReviewDetails(review),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Delete Review',
                onPressed: () => _deleteReview(review),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStarRating(int rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(
        Icon(
          i <= rating ? Icons.star : Icons.star_border,
          color: const Color(0xFFF9A825),
          size: 18,
        ),
      );
    }
    return stars;
  }

  Widget _buildPagination() {
    final totalCount = _reviewsResult?.count ?? 0;
    final totalPages = (totalCount / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadReviews();
                  }
                : null,
          ),
          const SizedBox(width: 8),
          Text('Page $_currentPage of $totalPages', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadReviews();
                  }
                : null,
          ),
          const SizedBox(width: 20),
          Text('Total: $totalCount reviews', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  void _showReviewDetails(Review review) {
    showDialog(
      context: context,
      builder: (context) {
        return DetailDialog(
          icon: Icons.rate_review,
          title: 'Review Details',
          subtitle: review.adTitle,
          children: [
            DetailRow(icon: Icons.person, label: 'Reviewer', value: review.reviewerEmail),
            const DetailDivider(),
            DetailRow(icon: Icons.person_outline, label: 'Reviewed User', value: review.reviewedUserEmail),
            const DetailDivider(),
            DetailRow(icon: Icons.article, label: 'Ad', value: review.adTitle),
            const DetailDivider(),
            DetailRow(icon: Icons.calendar_today, label: 'Date', value: formatDateTime(review.createdAt)),
            const DetailDivider(),
            DetailRow(
              icon: Icons.star,
              label: 'Rating',
              valueWidget: Row(children: _buildStarRating(review.rating ?? 0)),
            ),
            DetailSection(
              label: 'Comment',
              content: review.comment ?? 'No comment provided.',
            ),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReview(review);
              },
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReview(Review review) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Review'),
          content: Text(
            'Are you sure you want to delete this review by "${review.reviewerEmail}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _reviewProvider.delete(review.id!);
        if (context.mounted) {
          await buildSuccessAlert(context, 'Success', 'Review has been deleted successfully.');
        }
        _loadReviews();
      } catch (e) {
        if (context.mounted) {
          await buildErrorAlert(context, 'Error', e.toString(), e as Exception);
        }
      }
    }
  }
}
