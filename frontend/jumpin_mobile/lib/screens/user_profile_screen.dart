import 'package:flutter/material.dart';
import '../main.dart';
import '../models/user.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;
  final AuthProvider authProvider;

  const UserProfileScreen({
    super.key,
    required this.user,
    required this.authProvider,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with RouteAware {
  final _reviewProvider = ReviewProvider();
  final _userProvider = UserProvider();
  late User _user;
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isSubmittingReview = false;

  static const Color _primaryColor = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _reviewProvider.setToken(widget.authProvider.token);
    _userProvider.setToken(widget.authProvider.token);
    _loadUserData();
    _loadReviews();
  }

  Future<void> _loadUserData() async {
    // Best-effort enrichment of the profile already passed in; on failure we
    // keep showing the data we have.
    try {
      final fullUser = await _userProvider.getUserById(_user.id);
      if (fullUser != null && mounted) {
        setState(() {
          _user = fullUser;
        });
      }
    } catch (e) {
      logError('Failed to load user profile', e);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    _loadReviews();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reviews =
          await _reviewProvider.getReviews(reviewedUserId: _user.id);
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) showApiError(context, e);
    }
  }

  void _showAddReviewModal() {
    final formKey = GlobalKey<FormState>();
    int _rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Review',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Review for ${_user.fullName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Rating',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StatefulBuilder(
                        builder: (context, setState) => Row(
                          children: List.generate(
                            5,
                            (index) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rating = index + 1;
                                });
                              },
                              child: Icon(
                                Icons.star,
                                size: 40,
                                color: index < _rating
                                    ? Colors.amber
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: commentController,
                        decoration: InputDecoration(
                          labelText: 'Comment (optional)',
                          hintText: 'Share your experience...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value != null && value.trim().length > 500) {
                            return 'Comment must not exceed 500 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmittingReview
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;

                                  setState(() {
                                    _isSubmittingReview = true;
                                  });

                                  try {
                                    await _reviewProvider.createReview(
                                      reviewerId:
                                          widget.authProvider.currentUser!.id,
                                      reviewedUserId: _user.id,
                                      rating: _rating,
                                      comment: commentController.text.trim(),
                                    );

                                    setState(() {
                                      _isSubmittingReview = false;
                                    });

                                    if (mounted) {
                                      Navigator.pop(context);
                                      await _loadReviews();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Review added successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    setState(() {
                                      _isSubmittingReview = false;
                                    });
                                    if (mounted) showApiError(context, e);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmittingReview
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Submit Review',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = widget.authProvider.currentUser?.id == _user.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_user.fullName),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: _primaryColor.withOpacity(0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: _user.fullProfileImageUrl != null
                                  ? NetworkImage(_user.fullProfileImageUrl!)
                                  : null,
                              child: _user.fullProfileImageUrl == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user.fullName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_user.email != null)
                                    Text(
                                      _user.email!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (_user.phone != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _user.phone!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                  if (_user.isVip)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'VIP Member',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.amber[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn('Ads', _user.totalAds ?? 0),
                            _buildRatingColumn('Average Rating', _user.averageRating ?? 0),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.authProvider.isLoggedIn &&
                                widget.authProvider.currentUser?.id !=
                                    _user.id)
                              ElevatedButton.icon(
                                onPressed: _showAddReviewModal,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Review'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_reviews.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'No reviews yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: review.fullReviewerProfileImageUrl !=
                                                    null
                                                ? NetworkImage(
                                                    review.fullReviewerProfileImageUrl!)
                                                : null,
                                            child: review.fullReviewerProfileImageUrl == null
                                                ? const Icon(Icons.person, size: 20)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  review.reviewerName ?? 'Unknown',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    ...List.generate(
                                                      5,
                                                      (i) => Icon(
                                                        Icons.star,
                                                        size: 16,
                                                        color: i < review.rating
                                                            ? Colors.amber
                                                            : Colors.grey[300],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      review.rating.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatDate(review.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (review.comment != null &&
                                          review.comment!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            review.comment!,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingColumn(String label, double value) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value > 0) const Icon(Icons.star, color: Colors.amber, size: 18),
            if (value > 0) const SizedBox(width: 4),
            Text(
              value > 0 ? value.toStringAsFixed(1) : 'None',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
