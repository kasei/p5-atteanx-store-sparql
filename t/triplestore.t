=pod

=encoding utf-8

=head1 PURPOSE

Run standard Test::Attean::TripleStore tests

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Roo;
use RDF::Trine::Model;
use RDF::Trine qw(statement iri blank literal);
use RDF::Endpoint;
use Test::LWP::UserAgent;
use HTTP::Message::PSGI;
#use Carp::Always;

sub create_store {
	my $self = shift;
	my %args        = @_;
	my $quads       = $args{quads} // [];
	my $model = RDF::Trine::Model->temporary_model; # For creating endpoint
	foreach my $atteanquad (@{$quads}) {
		my $s = iri($atteanquad->subject->value);
		if ($atteanquad->subject->is_blank) {
			$s = blank($atteanquad->subject->value);
		}
		my $p = iri($atteanquad->predicate->value);
		my $o = iri($atteanquad->object->value);
		if ($atteanquad->object->is_literal) {
			$o = literal($atteanquad->object->value, $atteanquad->object->language, $atteanquad->object->datatype);
		} else {
			$o = blank($atteanquad->object->value);
		}
		$model->add_statement(statement($s, $p, $o));
	}
	my $end = RDF::Endpoint->new($model);
	my $app = sub {
		my $env 	= shift;
		my $req 	= Plack::Request->new($env);
		my $resp	= $end->run( $req );
		return $resp->finalize;
	};
	my $useragent = Test::LWP::UserAgent->new;
	$useragent->register_psgi('localhost', $app);
	# Now, we should just have had a URL of the endpoint
	my $url = 'http://localhost:5000/sparql';
	my $store = Attean->get_store('SPARQL')->new(endpoint_url => $url,
                                                ua => $useragent
                                               );
	return $store;
}

with 'Test::Attean::TripleStore';
run_me;

done_testing;
