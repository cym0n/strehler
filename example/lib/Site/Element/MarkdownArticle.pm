package Site::Element::MarkdownArticle;

use Moo;
use Text::Markdown 'markdown';

extends 'Strehler::Element::Article';

sub text
{
    my $self = shift;
    my $text = shift;
    return markdown($text);
}

1;
