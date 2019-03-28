## Read libraries
library("scales")
library("dplyr")
library("ggplot2")

## Read arguments from command line
args <- commandArgs(trailingOnly = TRUE)

## For debugging
# arg 1 is $prereq
# args[1] <- "test/data/sample_chr21.unfiltered.liftover.edited.variants_summary.tsv"
# arg 2 is $target
# args[2] <- "test/data/sample_chr21.unfiltered.liftover.edited_report.pdf"

## Read data
data.df <- read.table(file = args[1], header = T, sep = "\t", stringsAsFactors = T)

## Reorder factor
data.df$variants <- factor(data.df$variants, levels = c("unmapped_variants", "mapped_variants_PASS", "mapped_variants_noPASS","total_variants","mapped_variants"))

### test factor
##factor(data.df$variants)

## extract total variants value
total_variants = data.df[data.df$variants=="total_variants","number"]
## Calculate percentage of variants
data.df$percentage <- percent(data.df$number / total_variants)

## Keep only informative rows for pie chart
pie.df <- data.df %>% filter(variants == "unmapped_variants" | variants == "mapped_variants_PASS" | variants == "mapped_variants_noPASS") %>% droplevels()

## Change variants column text to pass info to legend in downstream plotting
pie.df$variants <- paste(pie.df$percentage,pie.df$variants,"(",pie.df$number,")")

## plot pie chart
# Create pie chart
pie.p <- ggplot(pie.df, aes(x="", y=number, fill=variants)) +
  geom_bar(width = 1, stat = "identity", color = "black") +
  coord_polar("y", start=0) +
  scale_fill_manual(values=c("indianred", "forestgreen", "gray40")) +
  ggtitle( "gnomAD variants remaped to new genome version") +
  labs( subtitle = paste("total variants:", total_variants, "\nfile:",args[1]),
       caption = date() ) + 
  theme_minimal() +
  theme(text = element_text(size=10),
        plot.subtitle = element_text(size=5),
        axis.text=element_blank(),
        axis.title = element_blank(),
        axis.line = element_blank(),
        legend.title = element_blank(),
        legend.spacing.x = unit(0.3, 'cm'))

# print pie
#pie.p

ggsave(filename = args[2], plot = pie.p, device = "pdf", width = 10.8, height = 7.2 , units = "cm", dpi = 300)