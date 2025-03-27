import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GraphQLService {
  static HttpLink httpLink = HttpLink("http://localhost:4000/");

  static GraphQLClient client = GraphQLClient(
    cache: GraphQLCache(),
    link: httpLink,
  );

  static Future<Map<String, dynamic>> authenticateUser(String email, String password) async {
    print("Starting authentication for user: $email");

    String mutation = """
      mutation {
        login(username: "$email", password: "$password") {
          password
        }
      }
    """;

    final MutationOptions options = MutationOptions(document: gql(mutation));
    final QueryResult result = await client.mutate(options);

    if (result.hasException) {
      print("❌ Authentication failed: ${result.exception.toString()}");
      return {"error": "❌ Authentication Failed"};
    } else {
      print("✅ Authentication successful for user: $email");
      return {"password": result.data?["login"]["password"]};
    }
  }

  static Future<Map<String, dynamic>> getBooks() async {
    print("Fetching books...");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("password");

    if (token == null) {
      print("❌ Not authenticated. Token is missing.");
      return {"error": "❌ Not Authenticated"};
    }

    print("Using password: $token");

    final HttpLink authLink = HttpLink("http://localhost:4000/", defaultHeaders: {
      "Authorization": token,
    });

    final GraphQLClient authClient = GraphQLClient(
      cache: GraphQLCache(),
      link: authLink,
    );

    String query = """
      query {
        books {
          title
          author
        }
      }
    """;

    final QueryOptions options = QueryOptions(document: gql(query));
    final QueryResult result = await authClient.query(options);

    if (result.hasException) {
      print("❌ Failed to load books: ${result.exception.toString()}");
      return {"error": "❌ Failed to Load Books"};
    } else {
      print("✅ Books fetched successfully: ${result.data?["books"]}");
      return {"data": result.data?["books"] ?? []};
    }
  }
}