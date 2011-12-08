=xml
<document title="Contact Module">
    <synopsis>
        Contact form for sending emails.
    </synopsis>
    <warning>
        Work in progress.
    </warning>
=cut

package contact;

# import libraries
use oyster 'module';
use exceptions;
use email;

=xml
    <function name="hook_load">
        <synopsis>
            Prepares queries to be used later.
        </synopsis>
        <note>
            This uses event::register_hook() to execute at the right times.
        </note>
    </function>
=cut

event::register_hook('load', 'hook_load');
sub hook_load {
    
    # pages cant be named this!
    our @reserved_urls = ('contact', 'admin'); 

}

=xml
    <function name="contact_form">
        <synopsis>
            Print and process the contact form requests.
        </synopsis>
    </function>
=cut

sub contact_form {
    
    #user::print_module_permissions('contact');
    style::include_template('contact_form');
    
    # If the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {
        
        my $destination = 'contact@bitpiston.com';
        my $gmtime      = datetime::gmtime();
        my $name        = $INPUT{'contact_author'};
        my $email       = $INPUT{'contact_email'};
        my $subject     = $INPUT{'contact_subject'};
        my $message     = $INPUT{'contact_message'};
        my $cc          = defined $INPUT{'contact_cc'} ? 1 : 0;
        
        # Validate post
        my $success = try {
            my @errors;
            
            # Check permissions
            #user::require_permission('contact_submit');
            
            # Has a name?
            push @errors, 'Please enter your name into the form.' if length $name < 2;
            
            # Valid email address?
            #push @errors, 'The email address you entered is not valid.' if email::is_valid_email($email);
            push @errors, 'The email address you entered is not valid. Please make sure you entered your address correctly.' unless $email =~ /^[a-zA-Z0-9._%-]+@[a-zA-Z0-9._%-]+\.[a-zA-Z]{2,6}$/;
            
            # Has a subject?
            push @errors, 'Please enter a subject into the form.' if length $subject < 2;
            
            # Has a message?
            push @errors, 'Please enter a message to send.' if length $message < 3;
       
            # Throw errors if any
            throw 'validation_error' => @errors if @errors > 0;
            
        };
        
        # If validation fails 
        if (!$success) {
            print "\t<contact action=\"view\">\n";
            print "\t\t<name>" . $name . "</name>\n";
            print "\t\t<subject>" . $subject . "</subject>\n";
            print "\t\t<message>" . $message . "</message>\n";
            print "\t\t<email>" . $email . "</email>\n";
            print "\t\t<cc>" . $cc . "</cc>\n";
            print "\t</contact>\n";
        }
        
        # If validation succeeded 
        elsif ($success) {
            my $from = oyster::shell_escape($name) . ' <' . oyster::shell_escape($email) . '>';
            
            print "\t<contact action=\"confirmation\" />\n";
            
            # Send the email
            if ($cc == 1) {
                email::send(    
                    to => $destination, 
                    subject => oyster::shell_escape($subject), 
                    from => $from, 
                    cc => oyster::shell_escape($email), 
                    oyster::shell_escape($message)
                );
            }
            else {
                email::send(    
                    to => $destination, 
                    subject => oyster::shell_escape($subject), 
                    from => $from, 
                    oyster::shell_escape($message)
                );
            }
        }           
    }    
    
    # If the form hasn't been submitted...
    else {
        
        # print the page
        print "\t<contact action=\"view\" />\n";
    }
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2011