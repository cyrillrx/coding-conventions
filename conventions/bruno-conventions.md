# Bruno API Testing Conventions

This document outlines the conventions and best practices for using [Bruno](https://www.usebruno.com/) for API testing. Bruno collections are typically located in a `bruno` directory at the project root.

## 1. Purpose of Bruno Collections

Bruno is used for:
- **API Functional Testing**: Ensuring individual API endpoints behave as expected.
- **API Integration Testing**: Verifying the interaction between different API endpoints or services.
- **API Documentation**: Providing executable examples of how to interact with the API.
- **Pre-deployment Checks**: Running critical API tests before deploying new backend versions.

## 2. Bruno Collection Structure

Collections should be organized logically within the `bruno` directory. A suggested structure:

```
bruno/
├── <service-name>/            # e.g. spring-server, rust-backend
│   ├── <feature-area>/        # e.g. auth, campaigns, creatures
│   │   ├── GET_all_campaigns.bru
│   │   ├── POST_create_campaign.bru
│   │   └── ...
│   ├── environments/
│   │   ├── local.bru
│   │   └── production.bru
│   └── setup.bru              # Optional: global setup requests (e.g. login to get a token)
├── common/                    # Requests/variables shared across services
│   └── auth_token_env.bru
└── README.md                  # Explanation of collections and setup
```

## 3. Naming Conventions

- **Collection Folders**: Use `kebab-case` for service and feature-area folders (e.g. `spring-server`, `campaign-management`).
- **Request Files**: Use `HTTP_METHOD_description.bru` (e.g. `GET_all_campaigns.bru`, `POST_create_new_user.bru`). Descriptions should be concise and clearly indicate the request's purpose.

## 4. Environments

- **Environment Files**: Each service should have an `environments` folder containing `[env-name].bru` files (e.g. `local.bru`, `production.bru`).
- **Variables**: Use environment variables for host URLs, API keys, and other environment-specific values.
    - Prefix environment-specific variables with `BASE_URL`, `API_KEY`, etc.
    - Example `local.bru`:
        ```
        vars {
          BASE_URL: http://localhost:8080
          AUTH_TOKEN:
        }
        ```

## 5. Request Best Practices

- **Clear Purpose**: Each request should have a single, clear purpose.
- **Descriptive Names**: The request name should accurately reflect what it does.
- **Assertions**: Include assertions to validate responses (status codes, body content, headers) in Bruno's `Tests` tab.
    ```javascript
    test("Status code is 200 OK", function() {
      expect(res.status).to.equal(200);
    });
    test("Response contains a list of campaigns", function() {
      expect(res.body).to.be.an('array');
      expect(res.body[0]).to.have.property('id');
    });
    ```
- **Pre-request Scripts**: Use pre-request scripts for dynamic data generation, authentication-token acquisition, or setting up prerequisites.
- **Post-request Scripts**: Use post-request scripts to extract data from responses (e.g. an ID from a `POST` to be reused in a later `GET` or `DELETE`) and save it to environment variables.
    ```javascript
    const response = res.body;
    if (response && response.id) {
      bru.setEnvVar('createdCampaignId', response.id);
    }
    ```
- **Variables**: Use Bruno's `{{variableName}}` syntax for referencing variables (environment, collection, or local).

## 6. Authentication

- **Token Management**: For APIs requiring authentication tokens (JWT, OAuth), use a dedicated request or pre-request script to obtain the token and store it as an environment variable (e.g. `AUTH_TOKEN`). Subsequent requests reference this variable in their `Authorization` header.

## 7. Version Control

- **Commit Bruno Files**: `.bru` files are plain text and should be committed to Git, enabling version control, collaboration, and review.

## 8. CI/CD Integration

- **CLI Runner**: Consider integrating Bruno's CLI runner (`bru`) into CI/CD pipelines to automate API tests, ensuring API health and correctness with every code change.
