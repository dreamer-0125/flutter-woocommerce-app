//  Label StoreMax
//
//  Created by Anthony Gordon.
//  2025, WooSignal Ltd. All rights reserved.
//

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import 'package:flutter/material.dart';
import '/app/forms/login_form.dart';
import '/resources/widgets/buttons/buttons.dart';
import '/resources/widgets/store_logo_widget.dart';
import '/app/events/login_event.dart';
import '/resources/pages/account_register_page.dart';
import '/bootstrap/app_helper.dart';
import '/bootstrap/helpers.dart';
import '/resources/widgets/buttons.dart';
import '/resources/widgets/woosignal_ui.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:wp_json_api/exceptions/incorrect_password_exception.dart';
import 'package:wp_json_api/exceptions/invalid_email_exception.dart';
import 'package:wp_json_api/exceptions/invalid_nonce_exception.dart';
import 'package:wp_json_api/exceptions/invalid_username_exception.dart';
import 'package:wp_json_api/models/responses/wp_user_login_response.dart';
import 'package:wp_json_api/wp_json_api.dart';

class AccountLoginPage extends NyStatefulWidget {
  static RouteView path = ("/account-login", (_) => AccountLoginPage());
  final bool showBackButton;
  AccountLoginPage({super.key, this.showBackButton = true})
      : super(child: () => _AccountLoginPageState());
}

class _AccountLoginPageState extends NyPage<AccountLoginPage> {
  LoginForm form = LoginForm();

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              StoreLogo(height: 100),
              SizedBox(height: 30),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trans("Login"),
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
                      trans("Welcome back! Please login to your account."),
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
                child: NyForm(
                    form: form,
                    crossAxisSpacing: 15,
                    footer: Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Button.primary(
                          text: trans("Login"),
                          submitForm: (
                            form,
                            (data) async {
                              NyLogger.debug('📝 Login form submitted');
                              await _loginUser(
                                  data['email'], data['password']);
                            }
                          ),
                        ))),
              ),
              SizedBox(height: 20),
              TextButton(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.account_circle,
                      color: (Theme.of(context).brightness == Brightness.light)
                          ? Colors.black38
                          : Colors.white70,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        trans("Create an account"),
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ],
                ),
                onPressed: () {
                  NyLogger.debug('🔀 Navigating to registration page');
                  routeTo(AccountRegistrationPage.path);
                },
              ),
              SizedBox(height: 10),
              LinkButton(
                  title: trans("Forgot Password"),
                  action: () {
                    NyLogger.debug('🔑 Forgot password button tapped');
                    String? forgotPasswordUrl =
                        AppHelper.instance.appConfig!.wpLoginForgotPasswordUrl;
                    if (forgotPasswordUrl != null) {
                      NyLogger.info('🌐 Opening forgot password URL');
                      openBrowserTab(url: forgotPasswordUrl);
                    } else {
                      NyLogger.warning(
                          "⚠️ No URL found for \"forgot password\".\nAdd your forgot password URL here https://woosignal.com/dashboard/apps");
                    }
                  }),
              SizedBox(height: 20),
              widget.showBackButton
                  ? Column(
                      children: [
                        Divider(height: 1),
                        SizedBox(height: 10),
                        LinkButton(
                          title: trans("Back"),
                          action: () {
                            NyLogger.debug('⬅️ Back button pressed');
                            Navigator.pop(context);
                          },
                        ),
                        SizedBox(height: 20),
                      ],
                    )
                  : SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  _loginUser(String email, String password) async {
    NyLogger.info('🔐 Login attempt started for email: $email');
    
    if (email.isNotEmpty) {
      email = email.trim();
      NyLogger.debug('✂️ Email trimmed: $email');
    }

    await lockRelease('login_button', perform: () async {
      WPUserLoginResponse? wpUserLoginResponse;
      try {
        NyLogger.debug('🌐 Calling WPJsonAPI login endpoint...');
        wpUserLoginResponse = await WPJsonAPI.instance.api(
            (request) => request.wpLogin(email: email, password: password));
        
        NyLogger.info('✅ Login API call successful');
        NyLogger.debug('📦 Login response status: ${wpUserLoginResponse?.status}');
      } on InvalidNonceException catch (e) {
        NyLogger.error('❌ InvalidNonceException during login: ${e.toString()}');
        showToast(
            title: trans("Invalid details"),
            description:
                trans("Something went wrong, please contact our store"),
            style: ToastNotificationStyleType.danger);
      } on InvalidEmailException catch (e) {
        NyLogger.warning('⚠️ InvalidEmailException: $email not found in system');
        showToast(
            title: trans("Invalid details"),
            description: trans("That email does not match our records"),
            style: ToastNotificationStyleType.danger);
      } on InvalidUsernameException catch (e) {
        NyLogger.warning('⚠️ InvalidUsernameException: ${e.toString()}');
        showToast(
            title: trans("Invalid details"),
            description: trans("That username does not match our records"),
            style: ToastNotificationStyleType.danger);
      } on IncorrectPasswordException catch (e) {
        NyLogger.warning('⚠️ IncorrectPasswordException for email: $email');
        showToast(
            title: trans("Invalid details"),
            description: trans("That password does not match our records"),
            style: ToastNotificationStyleType.danger);
      } on Exception catch (e) {
        NyLogger.error('❌ Generic exception during login: ${e.toString()}');
        showToast(
            title: trans("Oops!"),
            description: trans("Invalid login credentials"),
            style: ToastNotificationStyleType.danger,
            icon: Icons.account_circle);
      }

      if (wpUserLoginResponse == null) {
        NyLogger.warning('⚠️ Login response is null, aborting login flow');
        return;
      }

      if (wpUserLoginResponse.status != 200) {
        NyLogger.warning('⚠️ Login response status is not 200: ${wpUserLoginResponse.status}');
        return;
      }

      NyLogger.info('🎉 Login successful, triggering LoginEvent');
      event<LoginEvent>();

      showToast(
          title: trans("Hello"),
          description: trans("Welcome back"),
          style: ToastNotificationStyleType.success,
          icon: Icons.account_circle);
      
      NyLogger.debug('🔄 Navigating to redirect route: ${UserAuth.instance.redirect}');
      if (!mounted) {
        NyLogger.warning('⚠️ Widget not mounted, skipping navigation');
        return;
      }
      
      navigatorPush(context,
          routeName: UserAuth.instance.redirect, forgetLast: 1);
      NyLogger.info('✅ Login flow completed successfully');
    });
  }
}
