package Strehler::Dashboard;

use strict;
use Cwd 'abs_path';
use Dancer2 0.154000;
use Strehler::Dancer2::Plugin::Admin; 
use Data::Dumper;

my $module_file_path = __FILE__;
my $root_path = abs_path($module_file_path);
$root_path =~ s/Dashboard\.pm//;

my $form_path = $root_path . 'forms';

set views => $root_path . 'views';

get '/' => sub {
    my %navbar;
    $navbar{'home'} = "active";
    my $dashboard_data = config->{'Strehler'}->{'dashboard'};
    my $elid = 0;
    foreach my $el (@{$dashboard_data})
    {
        $el->{id} = $elid++;
        if($el->{'type'} eq 'list')
        {
            my $class = Strehler::Helpers::class_from_entity($el->{'entity'});
            my $elements = $class->get_list({ entries_per_page => -1, 
                                              category => $el->{'category'}, 
                                              language => config->{'Strehler'}->{'default_language'}, 
                                              published => 1
                                            });
            my @list = @{$elements->{'to_view'}};
            $el->{'counter'} = $#list+1;
        }
        elsif($el->{'type'} eq 'page')
        {
            my $total_elements = 0;
            my $published_elements = 0;
            foreach my $piece (@{$el->{'elements'}})
            {
                $total_elements++;
                my $class = Strehler::Helpers::class_from_entity($piece->{'entity'});
                my $by = $piece->{'by'} || 'date';
                my $latest_published;
                my $latest_unpublished;
                if($by eq 'date')
                {
                    $latest_published = $class->get_last_by_date($piece->{'category'}, config->{'Strehler'}->{'default_language'}, 1);
                    $latest_unpublished = $class->get_last_by_date($piece->{'category'}, config->{'Strehler'}->{'default_language'}, 0);
                }
                elsif($by eq 'order')
                {
                    $latest_published = $class->get_last_by_order($piece->{'category'}, config->{'Strehler'}->{'default_language'}, 1);
                    $latest_unpublished = $class->get_last_by_order($piece->{'category'}, config->{'Strehler'}->{'default_language'}, 0);
                }
                if($latest_published)
                {
                    $published_elements++;
                    my %latest_data = $latest_published->get_ext_data(config->{'Strehler'}->{'default_language'});
                    $piece->{'latest_published'} =  \%latest_data;
                }
                else
                {
                    $piece->{'latest_published'} = undef;
                }
                if(! $latest_unpublished)
                {
                    $piece->{'latest_unpublished'} = undef;
                }
                elsif(! $latest_published)
                {
                    my %latest_unpub_data = $latest_unpublished->get_ext_data(config->{'Strehler'}->{'default_language'});
                    $piece->{'latest_unpublished'} = \%latest_unpub_data;
                }
                elsif($latest_published->get_attr('publish_date') >= $latest_unpublished->get_attr('publish_date'))
                {
                    $piece->{'latest_unpublished'} = undef;
                }
                else
                {
                    my %latest_unpub_data = $latest_unpublished->get_ext_data(config->{'Strehler'}->{'default_language'});
                    $piece->{'latest_unpublished'} = \%latest_unpub_data;
                }
            }
            $el->{'published_elements'} = $published_elements;
            $el->{'total_elements'} = $total_elements;
        }
    }
    template "admin/dashboard", { navbar => \%navbar, dashboard => config->{'Strehler'}->{'dashboard'}};
};

1;
