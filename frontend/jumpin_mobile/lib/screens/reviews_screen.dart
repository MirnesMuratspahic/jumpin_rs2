import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review.dart';
import '../providers/review_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/error_handler.dart';

class ReviewsScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final String? targetUserId;
  final String? targetUserName;

  const ReviewsScreen({
    super.key,
    required this.authProvider,
    this.targetUserId,
    this.targetUserName,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _reviewProvider = ReviewProvider();
  List<Review> _receivedReviews = [];
  List<Review> _givenReviews = [];
  bool _isLoading = true;

  static const Color _primaryColor = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _reviewProvider.setToken(widget.authProvider.token);
    _tabController = TabController(length: 2, vsync: this);
    _loadReviews();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    final userId = widget.authProvider.currentUser?.id;
    if (userId != null) {
      try {
        // Fetch received + given reviews in parallel.
        final results = await Future.wait([
          _reviewProvider.getReviews(reviewedUserId: userId),
          _reviewProvider.getReviews(reviewerId: userId),
        ]);
        setState(() {
          _receivedReviews = results[0];
          _givenReviews = results[1];
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) showApiError(context, e);
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || review.id == null) return;

    try {
      await _reviewProvider.deleteReview(review.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReviews();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Received (${_receivedReviews.length})'),
            Tab(text: 'Given (${_givenReviews.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReviewList(_receivedReviews, isReceived: true),
                _buildReviewList(_givenReviews, isReceived: false),
              ],
            ),
    );
  }

  Widget _buildReviewList(List<Review> reviews, {required bool isReceived}) {
    if (reviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadReviews,
        color: _primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 300,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isReceived ? Icons.star_border : Icons.rate_review,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isReceived ? 'No reviews received' : 'No reviews given',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          return _buildReviewCard(reviews[index], isReceived: isReceived);
        },
      ),
    );
  }

  Widget _buildReviewCard(Review review, {required bool isReceived}) {
    final userId = widget.authProvider.currentUser?.id;
    final canDelete = review.reviewerId == userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: review.reviewerProfileImage != null
                    ? ClipOval(
                        child: Image.network(
                          review.reviewerProfileImage!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : Icon(Icons.person, color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReceived
                          ? review.reviewerName ?? 'Anonymous'
                          : 'To: ${review.reviewedUserName ?? 'User'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (review.adTitle != null)
                      Text(
                        'Ad: ${review.adTitle}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (canDelete && !isReceived)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteReview(review),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                '${review.rating}/5',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
          if (review.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy').format(review.createdAt!),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }
}
