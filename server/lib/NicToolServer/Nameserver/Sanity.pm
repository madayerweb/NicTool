package NicToolServer::Nameserver::Sanity;
# ABSTRACT: sanity tests for nameservers

use strict;

@NicToolServer::Nameserver::Sanity::ISA = qw(NicToolServer::Nameserver);

sub new_nameserver {
    my ( $self, $data ) = @_;

    $self->push_sanity_error( 'nt_group_id',
        'Cannot add nameserver to a deleted group!' )
        if $self->check_object_deleted( 'group', $data->{'nt_group_id'} );

    # check the nameserver's the TTL
    if ( !exists $data->{'ttl'} ) {   # if new and no default, set default.
        $data->{'ttl'} = 86400;
    }
    $self->is_valid_ttl( $data ); # check the TTL

    # check characters
    if ( $data->{'name'} =~ /([^a-zA-Z0-9\-\.])/ ) {
        $self->{'errors'}->{'name'} = 1;
        push(
            @{ $self->{'error_messages'} },
            "Nameserver name contains an invalid character - \"$1\". Only A-Z, 0-9, . and - are allowed."
        );
    }

    # check that name is absolute.
    if ( $data->{'name'} !~ /\.$/ ) {
        $self->{'errors'}->{'name'} = 1;
        push(
            @{ $self->{'error_messages'} },
            "Nameserver name must be a fully-qualified domain name with a dot at the end, such as ns1.example.com. (notice the dot after .com...)"
        );
    }

    # check that parts of the name are valid
    my @parts = split( /\./, $data->{'name'} );
    foreach my $address (@parts) {
        if ( $address !~ /[a-zA-Z0-9\-]+/ ) {
            $self->{'errors'}->{'name'} = 1;
            push(
                @{ $self->{'error_messages'} },
                "Nameserver name must be a valid host."
            );
        }
        elsif ( $address =~ /^[\-]/ ) {   # can't start with a dash or a dot..
            $self->{'errors'}->{'name'} = 1;
            push(
                @{ $self->{'error_messages'} },
                "Parts of a nameserver name cannot start with a dash."
            );
        }
    }

    # check that export_format is valid
    unless ( $data->{'export_format'} eq "djb"
        || $data->{'export_format'} eq "bind"
        || $data->{'export_format'} eq "nt" )
    {
        $self->{'errors'}->{'export_format'} = 1;
        push( @{ $self->{'error_messages'} }, "Invalid output format." );
    }

    # check that the IP address is valid
    my @ip = split( /\./, $data->{'address'} );
    my $ip_error;
    $ip_error = 1 if ( $ip[0] !~ /^\d{1,3}$/ || $ip[0] < 1 || $ip[0] > 255 );
    my $ip0 = shift(@ip);
    foreach (@ip) {
        $ip_error = 1 if ( $_ !~ /^\d{1,3}/ || $_ < 0 || $_ > 255 );
        $_ = $_ + 0;
    }
    $ip_error          = 1 if ( $ip[2] < 1 );
    $ip0               = $ip0 + 0;
    $data->{'address'} = $ip0 . "." . $ip[0] . "." . $ip[1] . "." . $ip[2];
    if ($ip_error) {
        $self->{'errors'}->{'address'} = 1;
        push(
            @{ $self->{'error_messages'} },
            "Invalid IP address - $data->{'address'}"
        );
    }

    return $self->throw_sanity_error if ( $self->{'errors'} );
    $self->SUPER::new_nameserver($data);
}

sub edit_nameserver {
    my ( $self, $data ) = @_;

    $self->push_sanity_error( 'nt_nameserver_id',
        'Cannot edit deleted nameserver!' )
        if $self->check_object_deleted( 'nameserver',
        $data->{'nt_nameserver_id'} );

    my $dataobj = $self->get_nameserver($data);
    return $dataobj if $self->is_error_response($dataobj);

    $self->push_sanity_error( 'nt_nameserver_id',
        'Cannot edit nameserver in a deleted group!' )
        if $self->check_object_deleted( 'group', $dataobj->{'nt_group_id'} );

    $self->is_valid_ttl( $data ); # check the TTL

    if ( exists $data->{'name'} ) {

        # check characters
        if ( $data->{'name'} =~ /([^a-zA-Z0-9\-\.])/ ) {
            $self->{'errors'}->{'name'} = 1;
            push(
                @{ $self->{'error_messages'} },
                "Nameserver name contains an invalid character - \"$1\". Only A-Z, 0-9, . and - are allowed."
            );
        }

        # check that name is absolute.
        if ( $data->{'name'} !~ /\.$/ ) {
            $self->{'errors'}->{'name'} = 1;
            push(
                @{ $self->{'error_messages'} },
                "Nameserver name must be a fully-qualified domain name with a dot at the end, such as ns1.example.com. (notice the dot after .com...)"
            );
        }

        # check that parts of the name are valid
        my @parts = split( /\./, $data->{'name'} );
        foreach my $address (@parts) {
            if ( $address !~ /[a-zA-Z0-9\-]+/ ) {
                $self->{'errors'}->{'name'} = 1;
                push(
                    @{ $self->{'error_messages'} },
                    "Nameserver name must be a valid host."
                );
            }
            elsif ( $address =~ /^[\-]/ )
            {    # can't start with a dash or a dot..
                $self->{'errors'}->{'name'} = 1;
                push(
                    @{ $self->{'error_messages'} },
                    "Parts of a nameserver name cannot start with a dash."
                );
            }
        }
    }

    # check that export_format is valid
    if ( exists $data->{'export_format'} ) {
        unless ( $data->{'export_format'} eq "djb"
            || $data->{'export_format'} eq "bind"
            || $data->{'export_format'} eq "nt" )
        {
            $self->{'errors'}->{'export_format'} = 1;
            push( @{ $self->{'error_messages'} }, "Invalid output format." );
        }
    }

    # check that the IP address is valid
    if ( exists $data->{'address'} ) {
        my @ip = split( /\./, $data->{'address'} );
        my $ip_error;
        $ip_error = 1
            if ( $ip[0] !~ /^\d{1,3}$/ || $ip[0] < 1 || $ip[0] > 255 );
        my $ip0 = shift(@ip);
        foreach (@ip) {
            $ip_error = 1 if ( $_ !~ /^\d{1,3}/ || $_ < 0 || $_ > 255 );
            $_ = $_ + 0;
        }
        $ip_error = 1 if ( $ip[2] < 1 );
        $ip0 = $ip0 + 0;
        $data->{'address'}
            = $ip0 . "." . $ip[0] . "." . $ip[1] . "." . $ip[2];
        if ($ip_error) {
            $self->{'errors'}->{'address'} = 1;
            push(
                @{ $self->{'error_messages'} },
                "Invalid IP address - $data->{'address'}"
            );
        }
    }

    return $self->throw_sanity_error if ( $self->{'errors'} );
    $self->SUPER::edit_nameserver($data);
}

sub move_nameservers {
    my ( $self, $data ) = @_;

    # TODO TODO TODO - sanity
    #warn Dumper($data);

    $self->SUPER::move_nameservers($data);
}

sub get_group_nameservers {
    my ( $self, $data ) = @_;

    $self->search_params_sanity_check( $data,
        qw(name description address export_format status group_name) );
    return $self->throw_sanity_error if ( $self->{'errors'} );
    return $self->SUPER::get_group_nameservers($data);
}

sub is_valid_ttl {
    my ($self, $data) = @_;

    return if ! exists( $data->{'ttl'};

    if ( $data->{'ttl'} < 300 || $data->{'ttl'} > 2592000 ) ) {
        $self->{'errors'}->{'ttl'} = 1;
        push(
            @{ $self->{'error_messages'} },
            "Invalid TTL -- ttl must be > 300 and < 2,592,000"
        );
    }
};

1;

__END__

=head1 SYNOPSIS

Validate that nameservers have required params, no invalid chars, etc. 

=cut
