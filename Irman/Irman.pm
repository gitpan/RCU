=head1 NAME

RCU::Irman - RCU interface to libirman.

=head1 SYNOPSIS

   use RCU::Irman;

=head1 DESCRIPTION

See L<RCU>.

=over 4

=cut

package RCU::Irman;

use DynaLoader;
use Carp;
use POSIX ();
use Time::HiRes ();
use Errno ();
use Fcntl;

use RCU;

use base qw(RCU::Interface DynaLoader);

BEGIN {
   $VERSION = 0.01;
   bootstrap RCU::Irman $VERSION;
}

=item new <path>

Create an interface to the RCU receiver at serial port <path> (default
from in irman.conf used if omitted).

=cut

sub new {
   my $class = shift;
   my $path = shift;
   my $self = $class->SUPER::new();
   my $fh = local *IRMAN_FH;

   $self->{fh} = $fh;

   $self->{pid} = open $fh, "-|";
   if ($self->{pid} == 0) {
      select STDOUT; $|=1;
      eval {
         $SIG{HUP} = sub { _exit };
         !ir_init_commands or croak "unable to init irman command layer: $!";
         $self->{fd} = ir_init $path || ir_default_portname || croak "irman: no port specified";
         $self->{fd} >= 0 or croak "unable to connect to irman: $!";
         print "I\x00";
         for(;;) {
            my ($raw, $cooked) = _get_code;
            print "=".Time::HiRes::time."\x01$raw\x01$cooked\x00";
         }
      };
      if ($@) {
         $@ =~ s/\x00/\x01/g;
         print "E$@\x00";
      }
      #ir_finish;
      #ir_free_commands;
      POSIX::_exit(0);
   } elsif (!defined $self->{pid}) {
      die;
   }
   
   $self->get; # wait for I packet

   $self;
}

sub fd {
   fileno $_[0]->{fh};
}

sub _get {
   my $self = shift;
   my $fh = $self->{fh};
   local $/ = "\x00";
   $! = 0;
   my $code = <$fh>;
   if ("=" eq substr $code, 0, 1) {
      split /\x01/, substr $code, 1, -1;
   } elsif ($code =~ s/^E//) {
      die substr $code, 0, -1;
   } elsif ($code =~ /^I/) {
      # NOP
      ();
   } elsif ($! != Errno::EAGAIN) {
      delete $self->{fh}; # to make event stop
      croak "irman communication error ($!)";
   } else {
      ();
   }
}

sub get {
   fcntl $_[0]->{fh}, F_SETFL, 0;
   goto &_get;
}

sub poll {
   fcntl $_[0]->{fh}, F_SETFL, O_NONBLOCK;
   goto &_get;
}

1;

=back

=head1 AUTHOR

This perl extension was written by Marc Lehmann <pcg@goof.com>.





