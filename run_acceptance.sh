echo "10_apply_taxes_on_invoice_a_test.rb"
ruby test/acceptance/10_apply_taxes_on_invoice_a_test.rb --verbose 2>&1 >> run_acceptance_output.txt

echo "10_apply_taxes_on_invoice_b_test.rb"
ruby test/acceptance/10_apply_taxes_on_invoice_b_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "11_invoice_with_discount_test.rb"
ruby test/acceptance/11_invoice_with_discount_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "126_invoice_numbering_test.rb"
ruby test/acceptance/126_invoice_numbering_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "14_invoice_numbers_date_comment_test.rb"
ruby test/acceptance/14_invoice_numbers_date_comment_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "15_terms_on_invoice_details_test.rb"
ruby test/acceptance/15_terms_on_invoice_details_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "16_invoice_status_change_test.rb"
ruby test/acceptance/16_invoice_status_change_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "814_cas_test.rb"
ruby test/acceptance/814_cas_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "1_signup_test.rb"
ruby test/acceptance/1_signup_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "200_customers_grid_test.rb"
ruby test/acceptance/200_customers_grid_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "21_email_invoice_as_html_link_test.rb"
ruby test/acceptance/21_email_invoice_as_html_link_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "25_customer_add_edit_test.rb"
ruby test/acceptance/25_customer_add_edit_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "270_remail_activation_test.rb"
ruby test/acceptance/270_remail_activation_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "270_reset_password_test.rb"
ruby test/acceptance/270_reset_password_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "271_referral_test.rb"
ruby test/acceptance/271_referral_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "272_contest_test.rb"
ruby test/acceptance/272_contest_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "27_customer_and_contact_on_the_fly_test.rb"
ruby test/acceptance/27_customer_and_contact_on_the_fly_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "29_customer_summary_list_test.rb"
ruby test/acceptance/29_customer_summary_list_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "2_invoice_can_create_new_test.rb"
ruby test/acceptance/2_invoice_can_create_new_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "33_tax_preferences_test.rb"
ruby test/acceptance/33_tax_preferences_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "38_company_information_test.rb"
ruby test/acceptance/38_company_information_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "3_invoice_save_test.rb"
ruby test/acceptance/3_invoice_save_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "4_invoice_lookup_modify_test.rb"
ruby test/acceptance/4_invoice_lookup_modify_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "59_invoices_overview_test.rb"
ruby test/acceptance/59_invoices_overview_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "5_invoice_remove_test.rb"
ruby test/acceptance/5_invoice_remove_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "67_payments_record_offline_test.rb"
ruby test/acceptance/67_payments_record_offline_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "67_record_payments_test.rb"
ruby test/acceptance/67_record_payments_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "68_paypal_express_full_round_trip_via_sandbox.rb"
ruby test/acceptance/68_paypal_express_full_round_trip_via_sandbox.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "68_paypal_express_round_trip_via_sandbox.rb"
ruby test/acceptance/68_paypal_express_round_trip_via_sandbox.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "6_invoice_profile_test.rb"
ruby test/acceptance/6_invoice_profile_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "74_preview_invoice_in_HTML_test.rb"
ruby test/acceptance/74_preview_invoice_in_HTML_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "7_invoice_with_customer_test.rb"
ruby test/acceptance/7_invoice_with_customer_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "87_accept_invitation_test.rb"
ruby test/acceptance/87_accept_invitation_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "87_send_bookkeeping_invitation.rb"
ruby test/acceptance/87_send_bookkeeping_invitation.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "8_line_items_crud_test.rb"
ruby test/acceptance/8_line_items_crud_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "9_invoice_quantity_price_test.rb"
ruby test/acceptance/9_invoice_quantity_price_test.rb --verbose  2>&1 >> run_acceptance_output.txt

echo "9_updates_totals_by_ajax.rb"
ruby test/acceptance/9_updates_totals_by_ajax.rb --verbose  2>&1 >> run_acceptance_output.txt