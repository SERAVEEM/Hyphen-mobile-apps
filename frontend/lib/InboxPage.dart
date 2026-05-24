import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Segmented Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Chats'),
                    Tab(text: 'Notifications'),
                  ],
                ),
              ),
            ),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatsTab(context),
                  _buildNotificationsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsTab(BuildContext context) {
    final List<Map<String, dynamic>> mockChats = [
      {
        'name': 'Hypen Official',
        'isVerified': true,
        'lastMsg': 'Your registration was successful. Welcome to Hypen!',
        'time': '10:24 AM',
        'unread': true,
        'avatar': null,
        'reply': 'Hello! How can we help you with your Hypen account today?'
      },
      {
        'name': 'Retro Thrifter',
        'isVerified': false,
        'lastMsg': 'Is the leather jacket still available?',
        'time': 'Yesterday',
        'unread': false,
        'avatar': 'assets/images/user_avatar.png',
        'reply': 'Hi! Yes, the vintage leather jacket is still available. The condition is pristine with zero creases.'
      },
      {
        'name': 'Luxe Vintage Shop',
        'isVerified': true,
        'lastMsg': 'The shipping price is fixed at Rp 25.000.',
        'time': 'May 20',
        'unread': false,
        'avatar': null,
        'reply': 'Hello there! Let us know if you need help with any designer items in our inventory.'
      },
      {
        'name': 'Sarah Jenkins',
        'isVerified': false,
        'lastMsg': 'Can you send more detailed pictures of the collar?',
        'time': 'May 18',
        'unread': true,
        'avatar': null,
        'reply': 'Sure, here are a few close-ups showing the texture of the collar.'
      },
    ];

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: mockChats.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F1F1)),
      itemBuilder: (context, index) {
        final chat = mockChats[index];
        const Color brandBrown = Color(0xFF8C7355);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  name: chat['name'],
                  isVerified: chat['isVerified'],
                  receiverReply: chat['reply'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFF6F6F6),
                  backgroundImage: chat['avatar'] != null ? AssetImage(chat['avatar']) : null,
                  child: chat['avatar'] == null
                      ? Text(
                          chat['name'][0],
                          style: GoogleFonts.plusJakartaSans(
                            color: brandBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            chat['name'],
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: chat['unread'] ? FontWeight.bold : FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                          if (chat['isVerified']) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: brandBrown, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chat['lastMsg'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: chat['unread'] ? Colors.black87 : Colors.black45,
                          fontWeight: chat['unread'] ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Time and Unread Dot
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat['time'],
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (chat['unread'])
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: brandBrown,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTab(BuildContext context) {
    final List<Map<String, dynamic>> mockNotifications = [
      {
        'icon': Icons.local_shipping_outlined,
        'title': 'Pesanan Telah Dikirim!',
        'body': 'Paket dengan nomor resi HP-982183 sudah diserahkan ke kurir.',
        'time': '2 hours ago',
        'isPromo': false,
      },
      {
        'icon': Icons.sell_outlined,
        'title': 'Price Drop Alert!',
        'body': 'Barang vintage dari keranjang belanja Anda turun harga sebesar 10%!',
        'time': '5 hours ago',
        'isPromo': false,
      },
      {
        'icon': Icons.card_giftcard_outlined,
        'title': 'Voucher Premium Gratis',
        'body': 'Dapatkan diskon ongkir hingga Rp 20.000 dengan kode voucher HYPENSHIP.',
        'time': '1 day ago',
        'isPromo': true,
      },
      {
        'icon': Icons.check_circle_outline,
        'title': 'Verifikasi Berhasil',
        'body': 'Produk Vintage Knitwear Sweater Anda telah disetujui untuk dijual.',
        'time': '3 days ago',
        'isPromo': false,
      },
    ];

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: mockNotifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F1F1)),
      itemBuilder: (context, index) {
        final notif = mockNotifications[index];
        const Color brandBrown = Color(0xFF8C7355);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: notif['isPromo'] ? brandBrown.withOpacity(0.08) : const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notif['icon'],
                  color: notif['isPromo'] ? brandBrown : Colors.black87,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif['title'],
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['body'],
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif['time'],
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final String name;
  final bool isVerified;
  final String receiverReply;

  const ChatDetailPage({
    super.key,
    required this.name,
    required this.isVerified,
    required this.receiverReply,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Default initial mock messages
    _messages.add({
      'text': widget.receiverReply,
      'isMe': false,
      'time': '10:24 AM',
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': 'Just Now',
      });
    });
    _msgController.clear();
    _scrollToBottom();

    // Mock receiver reply after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text': 'Thank you for your message! This is a mock automated reply from the backend integration test interface.',
          'isMe': false,
          'time': 'Just Now',
        });
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF6F6F6),
              child: Text(
                widget.name[0],
                style: GoogleFonts.plusJakartaSans(
                  color: brandBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: brandBrown, size: 14),
                      ],
                    ],
                  ),
                  Text(
                    'Online',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg['text'], msg['isMe'], msg['time']);
              },
            ),
          ),

          // Bottom Send Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment Icon
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.black54),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attachments is pending backend.')),
                      );
                    },
                  ),

                  // Message Input Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _msgController,
                        style: GoogleFonts.plusJakartaSans(color: Colors.black, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.black38, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Action Button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: brandBrown,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    const Color brandBrown = Color(0xFF8C7355);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: isMe ? brandBrown : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black38,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
