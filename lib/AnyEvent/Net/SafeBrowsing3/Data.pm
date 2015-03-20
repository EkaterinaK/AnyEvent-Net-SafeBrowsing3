package AnyEvent::Net::SafeBrowsing3::Data;

use strict;
use utf8;
use Mouse;
use YAML;

=head1 NAME

AnyEvent::Net::SafeBrowsing3::Data - File storage object for any data 

=head1 SYNOPSIS

  use AnyEvent::Net::SafeBrowsing3::Data;

  my $data = AnyEvent::Net::SafeBrowsing3::Data->new({path => '/tmp/datafile'});
  ...
  $data->get();
  $data->set();

=head1 DESCRIPTION

File storage for any data, like Config YAML forrmat

=cut


=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

Create a AnyEvent::Net::SafeBrowsing3::Tarantool object

  my $storage = AnyEvent::Net::SafeBrowsing3::Tarantool->new({
      path => '/tmp/datafile',
  });

Arguments

=over 4

=item path

Required. Path to file

=back

=cut

has path   => (is => 'ro', isa => 'Str', required => 1);
has config => (is => 'rw', isa => 'HashRef', default => sub {return {updated => {}, mac_keys => {client_key => '', wrapped_key => ''}, full_hash_errors => {}}});

sub BUILD {
	my $self = shift;
	if( ! -f $self->path ){
		if(open(my $FILE,">",$self->path)){
			YAML::DumpFile($self->path, $self->config);
		}
		else {
			die "Can't write to config file";
		}
	}
	else {
		$self->config(YAML::LoadFile($self->path));
	}
	return;
}

sub get {
	my $self = shift;
	my $prop = shift;
	my $value = $self->config;
	foreach my $part (split '/', $prop){
		$value = eval {$value->{$part}};
		if($@){
			die "Can't access $prop. $@"
		}
	}
	return $value; 
}

sub set {
	my $self = shift;
	my $prop = shift;
	my $value = shift;
	if( $prop =~ m{^(.*)/([^/]*)$} ){
		if( ref $self->get($1) eq 'HASH'){
			$self->get($1)->{$2} = $value;
		}
		else {
			$self->set($1, {$2 => $value});
		}
	}
	else {
		$self->config->{$prop} = $value;
	}
	YAML::DumpFile($self->path, $self->config);
	return $prop;
}

sub delete {
	my $self = shift;
	my $prop = shift;
	my $value = shift;
	if( $prop =~ m{^(.*)/([^/]*)$} ){
		delete $self->get($1)->{$2};
	}
	else {
		delete $self->config->{$prop};
	}
	YAML::DumpFile($self->path, $self->config);
	return $prop;

}

no Mouse;
__PACKAGE__->meta->make_immutable();

