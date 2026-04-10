//  Label StoreMax
//
//  Created by Anthony Gordon.
//  2025, WooSignal Ltd. All rights reserved.
//

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import 'package:flutter/material.dart';
import '/app/events/login_event.dart';
import '/bootstrap/app_helper.dart';
import '/bootstrap/helpers.dart';
import '/resources/widgets/buttons.dart';
import '/resources/widgets/safearea_widget.dart';
import '/resources/widgets/woosignal_ui.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:woosignal/models/response/woosignal_app.dart';
import 'package:wp_json_api/exceptions/empty_username_exception.dart';
import 'package:wp_json_api/exceptions/existing_user_email_exception.dart';
import 'package:wp_json_api/exceptions/existing_user_login_exception.dart';
import 'package:wp_json_api/exceptions/invalid_nonce_exception.dart';
import 'package:wp_json_api/exceptions/user_already_exist_exception.dart';
import 'package:wp_json_api/exceptions/username_taken_exception.dart';
import 'package:wp_json_api/models/responses/wp_user_register_response.dart';
import 'package:wp_json_api/wp_json_api.dart';

class AccountRegistrationPage extends NyStatefulWidget {
  static RouteView path =
      ("/account-register", (_) => AccountRegistrationPage());

  AccountRegistrationPage({super.key})
      : super(child: () => _AccountRegistrationPageState());
}

class _AccountRegistrationPageState extends NyPage<AccountRegistrationPage> {
  final TextEditingController _tfEmailAddressController =
          TextEditingController(),
      _tfPasswordController = TextEditingController(),
      _tfFirstNameController = TextEditingController(),
      _tfLastNameController = TextEditingController();

  final WooSignalApp? _wooSignalApp = AppHelper.instance.appConfig;

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            NyLogger.debug('⬅️ Close button pressed on registration page');
            Navigator.pop(context);
          },
        ),
        title: Text(trans("Register")),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeAreaWidget(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trans("Create Account"),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      trans("Join us today! Please fill in your details."),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      (Theme.of(context).brightness == Brightness.light)
                          ? wsBoxShadow()
                          : null,
                  color: ThemeColor.get(context).backgroundContainer,
                ),
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: TextEditingRow(
                            heading: trans("First Name"),
                            controller: _tfFirstNameController,
                            shouldAutoFocus: true,
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          child: TextEditingRow(
                            heading: trans("Last Name"),
                            controller: _tfLastNameController,
                            shouldAutoFocus: false,
                            keyboardType: TextInputType.text,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    TextEditingRow(
                      heading: trans("Email address"),
                      controller: _tfEmailAddressController,
                      shouldAutoFocus: false,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 15),
                    TextEditingRow(
                      heading: trans("Password"),
                      controller: _tfPasswordController,
                      shouldAutoFocus: true,
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    PrimaryButton(
                      title: trans("Sign up"),
                      isLoading: isLocked('register_user'),
                      action: () {
                        NyLogger.debug('📝 Sign up button tapped');
                        _signUpTapped();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () {
                    NyLogger.debug('📄 Terms and conditions link tapped');
                    _viewTOSModal();
                  },
                  child: RichText(
                    text: TextSpan(
                      text:
                          '${trans("By tapping \"Register\" you agree to ")} ${AppHelper.instance.appConfig!.appName!}\'s ',
                      children: <TextSpan>[
                        TextSpan(
                            text: trans("terms and conditions"),
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '  ${trans("and")}  '),
                        TextSpan(
                            text: trans("privacy policy"),
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                      style: TextStyle(
                          color:
                              (Theme.of(context).brightness == Brightness.light)
                                  ? Colors.black45
                                  : Colors.white70),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  _signUpTapped() async {
    NyLogger.info('📝 Registration attempt started');
    
    String email = _tfEmailAddressController.text,
        password = _tfPasswordController.text,
        firstName = _tfFirstNameController.text,
        lastName = _tfLastNameController.text;

    NyLogger.debug('📋 Registration input - Email: $email, First Name: $firstName, Last Name: $lastName');

    if (email.isNotEmpty) {
      email = email.trim();
      NyLogger.debug('✂️ Email trimmed: $email');
    }

    if (!isEmail(email)) {
      NyLogger.warning('⚠️ Invalid email format: $email');
      showToast(
          title: trans("Oops"),
          description: trans("That email address is not valid"),
          style: ToastNotificationStyleType.danger);
      return;
    }

    if (password.length <= 5) {
      NyLogger.warning('⚠️ Password too short: ${password.length} characters (minimum 6 required)');
      showToast(
          title: trans("Oops"),
          description: trans("Password must be a min 6 characters"),
          style: ToastNotificationStyleType.danger);
      return;
    }

    NyLogger.debug('✅ Registration validation passed, proceeding with API call');

    await lockRelease('register_user', perform: () async {
      WPUserRegisterResponse? wpUserRegisterResponse;
      try {
        NyLogger.info('🌐 Calling WPJsonAPI registration endpoint...');
        NyLogger.debug('📦 Registration payload - Email: ${email.toLowerCase()}, First Name: $firstName, Last Name: $lastName');
        
        wpUserRegisterResponse = await WPJsonAPI.instance.api(
          (request) => request.wcRegister(
            email: email.toLowerCase(),
            password: password,
            args: {
              "first_name": firstName,
              "last_name": lastName,
            },
          ),
        );
        
        NyLogger.info('✅ Registration API call successful');
        NyLogger.debug('📦 Registration response status: ${wpUserRegisterResponse?.status}');
      } on UsernameTakenException catch (e) {
        NyLogger.warning('⚠️ UsernameTakenException: ${e.toString()}');
        showToast(
            title: trans("Oops!"),
            description: trans(e.message),
            style: ToastNotificationStyleType.danger);
      } on InvalidNonceException catch (e) {
        NyLogger.error('❌ InvalidNonceException during registration: ${e.toString()}');
        showToast(
            title: trans("Invalid details"),
            description:
                trans("Something went wrong, please contact our store"),
            style: ToastNotificationStyleType.danger);
      } on ExistingUserLoginException catch (e) {
        NyLogger.warning('⚠️ ExistingUserLoginException: ${e.toString()}');
        showToast(
            title: trans("Oops!"),
            description: trans("A user already exists"),
            style: ToastNotificationStyleType.danger);
      } on ExistingUserEmailException catch (e) {
        NyLogger.warning('⚠️ ExistingUserEmailException: $email already registered');
        showToast(
            title: trans("Oops!"),
            description: trans("That email is taken, try another"),
            style: ToastNotificationStyleType.danger);
      } on UserAlreadyExistException catch (e) {
        NyLogger.warning('⚠️ UserAlreadyExistException: ${e.toString()}');
        showToast(
            title: trans("Oops!"),
            description: trans("A user already exists"),
            style: ToastNotificationStyleType.danger);
      } on EmptyUsernameException catch (e) {
        NyLogger.warning('⚠️ EmptyUsernameException: ${e.toString()}');
        showToast(
            title: trans("Oops!"),
            description: trans(e.message),
            style: ToastNotificationStyleType.danger);
      } on Exception catch (e) {
        NyLogger.error('❌ Generic exception during registration: ${e.toString()}');
        printError(e.toString());
        showToast(
            title: trans("Oops!"),
            description: trans("Something went wrong"),
            style: ToastNotificationStyleType.danger);
      }

      if (wpUserRegisterResponse?.status != 200) {
        NyLogger.warning('⚠️ Registration response status is not 200: ${wpUserRegisterResponse?.status}');
        return;
      }

      NyLogger.info('🎉 Registration successful, triggering LoginEvent');
      event<LoginEvent>();

      showToast(
          title: "${trans("Hello")} $firstName",
          description: trans("you're now logged in"),
          style: ToastNotificationStyleType.success,
          icon: Icons.account_circle);
      
      NyLogger.debug('🔄 Navigating to redirect route: ${UserAuth.instance.redirect}');
      if (!mounted) {
        NyLogger.warning('⚠️ Widget not mounted, skipping navigation');
        return;
      }
      
      navigatorPush(context,
          routeName: UserAuth.instance.redirect, forgetLast: 2);
      NyLogger.info('✅ Registration flow completed successfully for user: $firstName $lastName');
    });
  }

  _viewTOSModal() async {
    NyLogger.debug('📋 Displaying TOS modal');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(trans("Actions")),
        content: Text(trans("View Terms and Conditions or Privacy policy")),
        actions: <Widget>[
          MaterialButton(
            onPressed: () {
              NyLogger.debug('📄 Terms and Conditions button tapped in modal');
              _viewTermsConditions();
            },
            child: Text(trans("Terms and Conditions")),
          ),
          MaterialButton(
            onPressed: () {
              NyLogger.debug('🔒 Privacy Policy button tapped in modal');
              _viewPrivacyPolicy();
            },
            child: Text(trans("Privacy Policy")),
          ),
          Divider(),
          TextButton(
            onPressed: () {
              NyLogger.debug('❌ Closing TOS modal');
              pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewTermsConditions() {
    NyLogger.info('🌐 Opening Terms and Conditions URL: ${_wooSignalApp!.appTermsLink}');
    Navigator.pop(context);
    openBrowserTab(url: _wooSignalApp!.appTermsLink!);
  }

  void _viewPrivacyPolicy() {
    NyLogger.info('🌐 Opening Privacy Policy URL: ${_wooSignalApp!.appPrivacyLink}');
    Navigator.pop(context);
    openBrowserTab(url: _wooSignalApp!.appPrivacyLink!);
  }
}
